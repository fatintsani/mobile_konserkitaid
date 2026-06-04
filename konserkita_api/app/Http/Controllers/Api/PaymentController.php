<?php

namespace App\Http\Controllers\Api;

use App\Models\Payment;
use App\Models\Ticket;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PaymentController extends BaseController
{
    public function notificationHandler(Request $request)
    {
        $payload = $request->all();
        $serverKey = config('services.midtrans.server_key');

        // 1. Validate Signature Key
        $calculatedSignature = hash('sha512', $payload['order_id'] . $payload['status_code'] . $payload['gross_amount'] . $serverKey);
        
        if ($calculatedSignature !== $payload['signature_key']) {
            return $this->sendError('Invalid signature key.', [], 403);
        }

        $orderId = $payload['order_id'];
        $transactionId = (int) str_replace('INV-', '', $orderId);
        $transactionStatus = $payload['transaction_status'];
        $fraudStatus = $payload['fraud_status'] ?? null;

        $transaction = Transaction::with('items')->find($transactionId);

        if (!$transaction) {
            return $this->sendError('Transaction not found.', [], 404);
        }

        DB::beginTransaction();
        try {
            // 2. Insert into payments table
            Payment::create([
                'transaction_id' => $transaction->id,
                'payment_type' => $payload['payment_type'] ?? null,
                'gateway_transaction_id' => $payload['transaction_id'] ?? null,
                'gross_amount' => $payload['gross_amount'] ?? null,
                'transaction_time' => $payload['transaction_time'] ?? null,
                'transaction_status' => $transactionStatus,
                'response_payload' => $payload,
            ]);

            // 3. Handle Status
            if ($transactionStatus == 'capture') {
                if ($fraudStatus == 'challenge') {
                    $transaction->update(['payment_status' => 'pending']);
                } else if ($fraudStatus == 'accept') {
                    $transaction->update(['payment_status' => 'success']);
                    $this->generateTickets($transaction);
                }
            } else if ($transactionStatus == 'settlement') {
                $transaction->update(['payment_status' => 'success']);
                $this->generateTickets($transaction);
            } else if ($transactionStatus == 'cancel' ||
              $transactionStatus == 'deny' ||
              $transactionStatus == 'expire' || 
              $transactionStatus == 'failure') {
                $transaction->update(['payment_status' => 'expired']); // Wait, expire should map to expired or failed
                $this->restoreStock($transaction);
            } else if ($transactionStatus == 'pending') {
                $transaction->update(['payment_status' => 'pending']);
            }

            DB::commit();
            return response()->json(['message' => 'Notification processed successfully.']);

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Failed to process notification.', ['error' => $e->getMessage()], 500);
        }
    }

    private function generateTickets(Transaction $transaction)
    {
        // Prevent double generation
        if ($transaction->tickets()->count() > 0) return;

        foreach ($transaction->items as $item) {
            for ($i = 0; $i < $item->quantity; $i++) {
                Ticket::create([
                    'transaction_id' => $transaction->id,
                    'ticket_type_id' => $item->ticket_type_id,
                    'user_id' => $transaction->user_id,
                    'ticket_code' => 'TKT-' . Str::upper(Str::random(12)), // Unique QR Code content
                    'is_used' => false,
                ]);
            }
        }

        \App\Models\Notification::create([
            'user_id' => $transaction->user_id,
            'title' => 'Pembayaran Berhasil',
            'message' => 'Tiket Anda telah berhasil diterbitkan. Silakan cek menu My Tickets.',
            'type' => 'payment_success',
        ]);
    }

    private function restoreStock(Transaction $transaction)
    {
        // Only restore if not already failed/expired to avoid double restore
        if ($transaction->getOriginal('payment_status') === 'failed' || $transaction->getOriginal('payment_status') === 'expired') {
            return;
        }

        foreach ($transaction->items as $item) {
            $item->ticketType->increment('stock', $item->quantity);
        }
    }

    public function status(Request $request, $id)
    {
        $query = Transaction::where('id', $id);

        if (!in_array($request->user()->role, ['admin', 'super_admin'])) {
            $query->where('user_id', $request->user()->id);
        }

        $transaction = $query->first();

        if (!$transaction) {
            return $this->sendError('Transaction not found.', [], 404);
        }
        
        $invoiceNumber = 'INV-' . str_pad($transaction->id, 6, '0', STR_PAD_LEFT);

        if ($transaction->payment_status === 'pending') {
            \Midtrans\Config::$serverKey = config('services.midtrans.server_key');
            \Midtrans\Config::$isProduction = config('services.midtrans.is_production');
            
            try {
                $midtransStatus = \Midtrans\Transaction::status($invoiceNumber);
                
                $status = $midtransStatus->transaction_status;
                $fraud = $midtransStatus->fraud_status ?? null;
                
                $newStatus = 'pending';
                if ($status == 'capture') {
                    if ($fraud == 'accept') $newStatus = 'success';
                } else if ($status == 'settlement') {
                    $newStatus = 'success';
                } else if (in_array($status, ['cancel', 'deny', 'expire', 'failure'])) {
                    $newStatus = 'expired';
                }
                
                if ($newStatus !== 'pending') {
                    $transaction->update(['payment_status' => $newStatus]);
                    if ($newStatus === 'success') {
                        $this->generateTickets($transaction);
                    } else if ($newStatus === 'expired') {
                        $this->restoreStock($transaction);
                    }
                }
            } catch (\Exception $e) {
                // Ignore if not found on Midtrans
            }
        }

        return $this->sendResponse([
            'id' => $transaction->id,
            'payment_status' => $transaction->payment_status,
        ], 'Payment status retrieved.');
    }
}

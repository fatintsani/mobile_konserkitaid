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

        // 1. Validate Signature Key (TODO: Implement actual Midtrans signature validation)
        // $signatureKey = hash('sha512', $payload['order_id'] . $payload['status_code'] . $payload['gross_amount'] . config('midtrans.server_key'));
        // if ($signatureKey !== $payload['signature_key']) { ... }

        $transactionId = $payload['order_id']; // Asumsi order_id dari midtrans adalah transaction->id
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
                'gross_amount' => $payload['gross_amount'] ?? null,
                'transaction_time' => $payload['transaction_time'] ?? null,
                'transaction_status' => $transactionStatus,
                'raw_response' => $payload,
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
              $transactionStatus == 'expire') {
                $transaction->update(['payment_status' => 'failed']);
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
    }

    private function restoreStock(Transaction $transaction)
    {
        foreach ($transaction->items as $item) {
            $item->ticketType->increment('stock', $item->quantity);
        }
    }
}

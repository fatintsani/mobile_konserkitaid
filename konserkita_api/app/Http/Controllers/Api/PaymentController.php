<?php

namespace App\Http\Controllers\Api;

use App\Models\Payment;
use App\Models\Ticket;
use App\Models\Transaction;
use App\Models\UserEventInteraction;
use App\Models\ReferralCode;
use App\Models\ReferralConversion;
use App\Models\ReferralReward;
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
        $transactionStatus = $payload['transaction_status'];
        $fraudStatus = $payload['fraud_status'] ?? null;

        if (Str::startsWith($orderId, 'SUB-')) {
            return $this->handleSubscriptionPayment($orderId, $transactionStatus, $fraudStatus);
        }

        $transactionId = (int) str_replace('INV-', '', $orderId);

        DB::beginTransaction();
        try {
            $transaction = Transaction::with('items')->lockForUpdate()->find($transactionId);

            if (!$transaction) {
                DB::rollBack();
                return $this->sendError('Transaction not found.', [], 404);
            }

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

    private function handleSubscriptionPayment($orderId, $transactionStatus, $fraudStatus)
    {
        DB::beginTransaction();
        try {
            $payment = \App\Models\SubscriptionPayment::where('invoice_number', $orderId)->lockForUpdate()->first();
            
            if (!$payment) {
                DB::rollBack();
                return $this->sendError('Subscription payment not found.', [], 404);
            }

            if ($transactionStatus == 'capture') {
                if ($fraudStatus == 'accept') {
                    $this->activateSubscription($payment);
                }
            } else if ($transactionStatus == 'settlement') {
                $this->activateSubscription($payment);
            } else if (in_array($transactionStatus, ['cancel', 'deny', 'expire', 'failure'])) {
                $payment->update(['payment_status' => 'failed']);
            }

            DB::commit();
            return response()->json(['message' => 'Subscription notification processed successfully.']);
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Failed to process subscription notification.', ['error' => $e->getMessage()], 500);
        }
    }

    private function activateSubscription($payment)
    {
        $payment->update([
            'payment_status' => 'paid',
            'paid_at' => now()
        ]);

        $subscription = $payment->subscription;
        $plan = $subscription->plan;

        $startsAt = now();
        $endsAt = $plan->billing_cycle === 'yearly' ? now()->addYear() : now()->addMonth();

        $subscription->update([
            'status' => 'active',
            'starts_at' => $startsAt,
            'ends_at' => $endsAt
        ]);

        \App\Models\Notification::create([
            'user_id' => $subscription->organizer->user_id,
            'title' => 'Subscription Activated',
            'message' => 'Your ' . $plan->name . ' subscription is now active!',
            'type' => 'subscription'
        ]);
    }

    private function generateTickets(Transaction $transaction)
    {
        // Prevent double generation
        if ($transaction->tickets()->count() > 0) return;

        $seatReservations = \App\Models\SeatReservation::where('transaction_id', $transaction->id)->get();
        $seatReservationsByTicketType = [];

        // If we have seat reservations, we need to map them. Wait, seat_reservations do not have ticket_type_id.
        // But the user bought X tickets of Type A (requires seat) and Y tickets of Type B (no seat).
        // The total number of seat_reservations should equal the total number of requires_seat tickets.
        $seatIndex = 0;

        foreach ($transaction->items as $item) {
            $ticketType = \App\Models\TicketType::find($item->ticket_type_id);

            for ($i = 0; $i < $item->quantity; $i++) {
                $seatId = null;
                if ($ticketType && $ticketType->requires_seat && isset($seatReservations[$seatIndex])) {
                    $seatId = $seatReservations[$seatIndex]->seat_id;
                    
                    // Mark the seat as sold
                    $seatReservations[$seatIndex]->update(['status' => 'sold']);
                    $seatIndex++;
                }

                Ticket::create([
                    'transaction_id' => $transaction->id,
                    'ticket_type_id' => $item->ticket_type_id,
                    'user_id' => $transaction->user_id,
                    'ticket_code' => 'TKT-' . Str::upper(Str::random(12)),
                    'is_used' => false,
                    'seat_id' => $seatId,
                ]);
            }
        }

        // Handle Referral Logic
        if ($transaction->referral_code_id) {
            $refCode = ReferralCode::lockForUpdate()->find($transaction->referral_code_id);
            if ($refCode && $transaction->user_id !== $refCode->user_id) {
                // Determine commission amount
                $commission = 0;
                if ($refCode->commission_type === 'percentage') {
                    $commission = ($refCode->commission_value / 100) * $transaction->total_amount;
                } else {
                    $commission = $refCode->commission_value;
                }

                if ($refCode->max_reward && $commission > $refCode->max_reward) {
                    $commission = $refCode->max_reward;
                }

                if ($commission > 0) {
                    $conversion = ReferralConversion::create([
                        'referral_code_id' => $refCode->id,
                        'referred_user_id' => $transaction->user_id,
                        'transaction_id' => $transaction->id,
                        'commission_amount' => $commission,
                        'status' => 'pending', // Waiting admin approval
                    ]);

                    ReferralReward::create([
                        'user_id' => $refCode->user_id,
                        'referral_conversion_id' => $conversion->id,
                        'amount' => $commission,
                        'status' => 'pending',
                    ]);

                    $refCode->increment('used_count');

                    \App\Models\Notification::create([
                        'user_id' => $refCode->user_id,
                        'title' => 'Reward Referral Pending',
                        'message' => 'Seseorang baru saja menggunakan kode referral Anda! Komisi sedang diproses.',
                        'type' => 'referral_pending',
                    ]);
                }
            }
        }

        \App\Models\Notification::create([
            'user_id' => $transaction->user_id,
            'title' => 'Pembayaran Berhasil',
            'message' => 'Tiket Anda telah berhasil diterbitkan. Silakan cek menu My Tickets.',
            'type' => 'payment_success',
        ]);

        // Log purchase for recommendation system
        UserEventInteraction::create([
            'user_id' => $transaction->user_id,
            'event_id' => $transaction->event_id,
            'interaction_type' => 'purchase',
            'weight' => 10,
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

        // Release seats
        \App\Models\SeatReservation::where('transaction_id', $transaction->id)
            ->update([
                'status' => 'available',
                'hold_expires_at' => null,
                'transaction_id' => null
            ]);
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

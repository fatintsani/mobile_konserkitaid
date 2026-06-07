<?php

namespace App\Http\Controllers\Api;

use App\Models\TicketType;
use App\Models\Transaction;
use App\Models\TransactionItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Midtrans\Config;
use Midtrans\Snap;

class CheckoutController extends BaseController
{
    public function process(\App\Http\Requests\Checkout\ProcessCheckoutRequest $request)
    {

        DB::beginTransaction();
        try {
            $user = $request->user();
            $totalAmount = 0;
            $itemsToInsert = [];
            $totalRequiredSeats = 0;

            // 1. Calculate total and check stock
            foreach ($request->tickets as $ticketData) {
                $ticketType = TicketType::lockForUpdate()->find($ticketData['ticket_type_id']);
                
                if ($ticketType->stock < $ticketData['quantity']) {
                    throw new \Exception("Not enough stock for ticket: {$ticketType->name}");
                }
                
                if ($ticketData['quantity'] > $ticketType->max_buy_per_transaction) {
                    throw new \Exception("Exceeded maximum buy limit for ticket: {$ticketType->name}");
                }

                $subtotal = $ticketType->price * $ticketData['quantity'];
                $totalAmount += $subtotal;

                $itemsToInsert[] = [
                    'ticket_type_id' => $ticketType->id,
                    'quantity' => $ticketData['quantity'],
                    'price' => $ticketType->price,
                    'subtotal' => $subtotal,
                ];

                if ($ticketType->requires_seat) {
                    $totalRequiredSeats += $ticketData['quantity'];
                }

                // Reduce stock
                $ticketType->stock -= $ticketData['quantity'];
                $ticketType->save();
            }

            if ($totalRequiredSeats > 0) {
                if (!$request->has('seat_ids') || !is_array($request->seat_ids) || count($request->seat_ids) !== $totalRequiredSeats) {
                    throw new \Exception("Please select exactly $totalRequiredSeats seats.");
                }

                $heldSeats = \App\Models\SeatReservation::where('event_id', $request->event_id)
                    ->whereIn('seat_id', $request->seat_ids)
                    ->where('user_id', $user->id)
                    ->where('status', 'held')
                    ->where('hold_expires_at', '>', now())
                    ->lockForUpdate()
                    ->get();

                if ($heldSeats->count() !== $totalRequiredSeats) {
                    throw new \Exception("Some selected seats are no longer held by you or have expired. Please re-select.");
                }
            }

            // Promo validation logic
            $discountAmount = 0;
            $promoCodeId = null;
            if ($request->filled('promo_code')) {
                $promo = \App\Models\PromoCode::where('code', $request->promo_code)->where('status', 'active')->lockForUpdate()->first();
                if (!$promo) {
                    throw new \Exception("Promo code not found or inactive.");
                }
                
                $now = \Carbon\Carbon::now();
                if ($promo->start_date && $now->lt($promo->start_date)) throw new \Exception("Promo code is not active yet.");
                if ($promo->end_date && $now->gt($promo->end_date)) throw new \Exception("Promo code has expired.");
                if ($promo->used >= $promo->quota) throw new \Exception("Promo code quota exceeded.");

                if ($promo->discount_type === 'percentage') {
                    $discountAmount = ($promo->discount_value / 100) * $totalAmount;
                    if ($promo->max_discount && $discountAmount > $promo->max_discount) {
                        $discountAmount = $promo->max_discount;
                    }
                } else {
                    $discountAmount = $promo->discount_value;
                }

                if ($discountAmount > $totalAmount) {
                    $discountAmount = $totalAmount;
                }
                $promoCodeId = $promo->id;
                
                // Increment used count
                $promo->increment('used');
            }

            // Referral validation logic
            $referralCodeId = null;
            if ($request->filled('referral_code')) {
                $refCode = \App\Models\ReferralCode::where('code', $request->referral_code)->where('status', 'active')->first();
                if (!$refCode) {
                    throw new \Exception("Referral code not found or inactive.");
                }
                
                if ($refCode->expired_at && $refCode->expired_at->isPast()) {
                    throw new \Exception("Referral code has expired.");
                }
                if ($refCode->usage_limit && $refCode->used_count >= $refCode->usage_limit) {
                    throw new \Exception("Referral code usage limit reached.");
                }
                if ($refCode->user_id === $user->id) {
                    throw new \Exception("You cannot use your own referral code.");
                }

                $referralCodeId = $refCode->id;
            }

            $finalAmount = $totalAmount - $discountAmount;

            // 2. Create Transaction
            $transaction = Transaction::create([
                'user_id' => $user->id,
                'subtotal' => $totalAmount,
                'discount_amount' => $discountAmount,
                'total_amount' => $finalAmount,
                'payment_status' => 'pending',
                'promo_code_id' => $promoCodeId,
                'referral_code_id' => $referralCodeId,
            ]);

            // 3. Create Transaction Items
            foreach ($itemsToInsert as $item) {
                TransactionItem::create(array_merge($item, [
                    'transaction_id' => $transaction->id,
                ]));
            }

            // 4. Update Seat Reservations
            if ($totalRequiredSeats > 0) {
                \App\Models\SeatReservation::where('event_id', $request->event_id)
                    ->whereIn('seat_id', $request->seat_ids)
                    ->update(['transaction_id' => $transaction->id]);
            }

            // Configure Midtrans
            Config::$serverKey = config('services.midtrans.server_key');
            Config::$isProduction = config('services.midtrans.is_production');
            Config::$isSanitized = config('services.midtrans.is_sanitized');
            Config::$is3ds = config('services.midtrans.is_3ds');
            $invoiceNumber = 'INV-' . str_pad($transaction->id, 6, '0', STR_PAD_LEFT);

            $params = [
                'transaction_details' => [
                    'order_id' => $invoiceNumber,
                    'gross_amount' => $finalAmount,
                ],
                'customer_details' => [
                    'first_name' => $user->name,
                    'email' => $user->email,
                    'phone' => '08123456789', // Default if phone not available
                ],
            ];

            $snapResponse = Snap::createTransaction($params);
            $snapToken = $snapResponse->token;
            $paymentUrl = $snapResponse->redirect_url;
            
            $transaction->update([
                'snap_token' => $snapToken,
                'payment_url' => $paymentUrl,
            ]);

            \App\Models\Notification::create([
                'user_id' => $user->id,
                'title' => 'Checkout Berhasil',
                'message' => 'Pesanan tiket Anda telah dibuat. Segera selesaikan pembayaran.',
                'type' => 'checkout',
            ]);

            DB::commit();
            $transaction->load('items.ticketType');
            $transaction->invoice_number = $invoiceNumber; // For JSON response

            return $this->sendResponse($transaction, 'Checkout successful.');

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Checkout failed.', ['error' => $e->getMessage()], 400);
        }
    }
}

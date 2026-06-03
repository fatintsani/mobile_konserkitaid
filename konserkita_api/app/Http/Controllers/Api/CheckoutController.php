<?php

namespace App\Http\Controllers\Api;

use App\Models\TicketType;
use App\Models\Transaction;
use App\Models\TransactionItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class CheckoutController extends BaseController
{
    public function process(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'tickets' => 'required|array',
            'tickets.*.ticket_type_id' => 'required|exists:ticket_types,id',
            'tickets.*.quantity' => 'required|integer|min:1',
        ]);

        if($validator->fails()){
            return $this->sendError('Validation Error.', $validator->errors(), 422);       
        }

        DB::beginTransaction();
        try {
            $user = $request->user();
            $totalAmount = 0;
            $itemsToInsert = [];

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

                // Reduce stock
                $ticketType->stock -= $ticketData['quantity'];
                $ticketType->save();
            }

            // 2. Create Transaction
            $transaction = Transaction::create([
                'user_id' => $user->id,
                'total_amount' => $totalAmount,
                'payment_status' => 'pending',
                // Dummy snap_token for now, replace with actual Midtrans Snap API call
                'snap_token' => 'SNAP-' . Str::upper(Str::random(10)), 
            ]);

            // 3. Create Transaction Items
            foreach ($itemsToInsert as $item) {
                TransactionItem::create(array_merge($item, [
                    'transaction_id' => $transaction->id,
                ]));
            }

            // TODO: Call Midtrans Snap API here to get actual snap_token
            // ...

            DB::commit();

            $transaction->load('items.ticketType');

            return $this->sendResponse($transaction, 'Checkout successful.');

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Checkout failed.', ['error' => $e->getMessage()], 400);
        }
    }
}

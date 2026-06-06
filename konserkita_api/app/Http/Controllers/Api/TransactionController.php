<?php

namespace App\Http\Controllers\Api;

use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends BaseController
{
    public function index(Request $request)
    {
        $transactions = Transaction::with(['items.ticketType.event', 'promoCode'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();
            
        $transactions->map(function ($transaction) {
            $transaction->invoice_number = 'INV-' . str_pad($transaction->id, 6, '0', STR_PAD_LEFT);
            $transaction->order_status = match($transaction->payment_status) {
                'paid' => 'completed',
                'expired', 'failed' => 'expired', // Or failed, but prompt says expired/failed mapping
                default => 'pending'
            };
            
            $firstItem = $transaction->items->first();
            if ($firstItem && $firstItem->ticketType && $firstItem->ticketType->event) {
                $transaction->event = $firstItem->ticketType->event;
            }
            return $transaction;
        });

        return $this->sendResponse($transactions, 'Transactions retrieved successfully.');
    }

    public function show(Request $request, $id)
    {
        $transaction = Transaction::with(['items.ticketType.event', 'tickets.ticketType', 'promoCode'])
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (is_null($transaction)) {
            return $this->sendError('Transaction not found.');
        }
        
        $transaction->invoice_number = 'INV-' . str_pad($transaction->id, 6, '0', STR_PAD_LEFT);
        $transaction->order_status = match($transaction->payment_status) {
            'paid' => 'completed',
            'expired', 'failed' => 'expired',
            default => 'pending'
        };

        $firstItem = $transaction->items->first();
        if ($firstItem && $firstItem->ticketType && $firstItem->ticketType->event) {
            $transaction->event = $firstItem->ticketType->event;
        }

        return $this->sendResponse($transaction, 'Transaction details retrieved successfully.');
    }
}

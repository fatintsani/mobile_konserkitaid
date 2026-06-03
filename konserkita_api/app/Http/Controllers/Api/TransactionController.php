<?php

namespace App\Http\Controllers\Api;

use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends BaseController
{
    public function index(Request $request)
    {
        $transactions = Transaction::with(['event'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return $this->sendResponse($transactions, 'Transactions retrieved successfully.');
    }

    public function show(Request $request, $id)
    {
        $transaction = Transaction::with(['event', 'tickets.ticketType'])
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (is_null($transaction)) {
            return $this->sendError('Transaction not found.');
        }

        return $this->sendResponse($transaction, 'Transaction details retrieved successfully.');
    }
}

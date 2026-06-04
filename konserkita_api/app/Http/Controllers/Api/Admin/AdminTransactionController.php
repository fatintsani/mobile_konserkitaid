<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Transaction;
use Illuminate\Http\Request;

class AdminTransactionController extends BaseController
{
    public function index(Request $request)
    {
        $status = $request->query('payment_status');

        $query = Transaction::with(['user', 'items.ticketType.event']);

        if ($status) {
            $query->where('payment_status', $status);
        }

        $transactions = $query->orderBy('created_at', 'desc')->paginate(10);

        return $this->sendResponse($transactions, 'Transactions retrieved successfully.');
    }

    public function show($id)
    {
        $transaction = Transaction::with(['user', 'items.ticketType.event', 'payment'])->find($id);

        if (!$transaction) {
            return $this->sendError('Transaction not found.', [], 404);
        }

        return $this->sendResponse($transaction, 'Transaction details retrieved successfully.');
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Refund;
use App\Models\Transaction;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RefundController extends Controller
{
    public function index(Request $request)
    {
        $refunds = Refund::with(['transaction.items.ticketType.event'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $refunds
        ]);
    }

    public function show(Request $request, $id)
    {
        $refund = Refund::with(['transaction.items.ticketType.event', 'transaction.tickets'])
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $refund
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'transaction_id' => 'required|exists:transactions,id',
            'reason' => 'required|string|max:1000',
        ]);

        $user = $request->user();

        return DB::transaction(function () use ($request, $user) {
            $transaction = Transaction::with(['tickets', 'items.ticketType.event'])
                ->lockForUpdate()
                ->where('user_id', $user->id)
                ->findOrFail($request->transaction_id);

            if ($transaction->payment_status !== 'success') {
                return response()->json([
                    'success' => false,
                    'message' => 'Hanya transaksi yang sudah berhasil dibayar yang dapat direfund.'
                ], 400);
            }

            if ($transaction->refund()->exists()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Transaksi ini sudah memiliki pengajuan refund aktif.'
                ], 400);
            }

            // Check if any ticket is used
            $hasUsedTickets = $transaction->tickets()->where('is_used', true)->exists();
            if ($hasUsedTickets) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tidak bisa refund karena ada tiket yang sudah digunakan.'
                ], 400);
            }

            // Check if event has started (assuming 1 event per transaction for simplicity, or check all)
            $eventStarted = false;
            foreach ($transaction->items as $item) {
                $event = $item->ticketType->event;
                $eventDateTime = \Carbon\Carbon::parse($event->date . ' ' . $event->time);
                if (now()->greaterThanOrEqualTo($eventDateTime)) {
                    $eventStarted = true;
                    break;
                }
            }

            if ($eventStarted) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tidak bisa refund karena event sudah dimulai atau selesai.'
                ], 400);
            }

            // Create refund
            $refund = Refund::create([
                'transaction_id' => $transaction->id,
                'user_id' => $user->id,
                'reason' => $request->reason,
                'status' => 'pending',
                'refund_amount' => $transaction->total_amount, // Default to full refund
                'requested_at' => now(),
            ]);

            // Create notification
            Notification::create([
                'user_id' => $user->id,
                'title' => 'Pengajuan Refund Diterima',
                'message' => 'Pengajuan refund Anda untuk transaksi #' . $transaction->id . ' sedang diproses.',
                'type' => 'refund',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Pengajuan refund berhasil dikirim.',
                'data' => $refund
            ], 201);
        });
    }
}

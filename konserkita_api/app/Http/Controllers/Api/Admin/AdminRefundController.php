<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Refund;
use App\Models\Notification;
use App\Models\Transaction;
use App\Models\ReferralConversion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Services\AdminAuditService;

class AdminRefundController extends Controller
{
    protected $auditService;

    public function __construct(AdminAuditService $auditService)
    {
        $this->auditService = $auditService;
    }
    public function index(Request $request)
    {
        $query = Refund::with(['transaction', 'user'])->latest();

        if ($request->has('status') && $request->status !== '') {
            $query->where('status', $request->status);
        }

        $refunds = $query->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $refunds
        ]);
    }

    public function show($id)
    {
        $refund = Refund::with(['transaction.items.ticketType.event', 'transaction.tickets', 'user'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $refund
        ]);
    }

    public function approve($id)
    {
        return DB::transaction(function () use ($id) {
            $refund = Refund::lockForUpdate()->findOrFail($id);

            if ($refund->status !== 'pending') {
                return response()->json(['success' => false, 'message' => 'Hanya refund pending yang bisa disetujui.'], 400);
            }

            $oldValues = $refund->toArray();
            $refund->update([
                'status' => 'approved',
                'approved_at' => now(),
            ]);

            $this->auditService->log(
                auth()->user(),
                'refund_approved',
                'refunds',
                $refund,
                $oldValues,
                $refund->toArray(),
                "Approved refund #{$refund->id}"
            );

            $refund->transaction()->update([
                'payment_status' => 'refund_approved'
            ]);

            Notification::create([
                'user_id' => $refund->user_id,
                'title' => 'Refund Disetujui',
                'message' => 'Pengajuan refund Anda untuk transaksi #' . $refund->transaction_id . ' telah disetujui dan menunggu proses transfer.',
                'type' => 'refund',
            ]);

            return response()->json(['success' => true, 'message' => 'Refund disetujui.']);
        });
    }

    public function reject(Request $request, $id)
    {
        $request->validate([
            'admin_note' => 'required|string|max:1000',
        ]);

        return DB::transaction(function () use ($request, $id) {
            $refund = Refund::lockForUpdate()->findOrFail($id);

            if ($refund->status !== 'pending') {
                return response()->json(['success' => false, 'message' => 'Hanya refund pending yang bisa ditolak.'], 400);
            }

            $oldValues = $refund->toArray();
            $refund->update([
                'status' => 'rejected',
                'admin_note' => $request->admin_note,
            ]);

            $this->auditService->log(
                auth()->user(),
                'refund_rejected',
                'refunds',
                $refund,
                $oldValues,
                $refund->toArray(),
                "Rejected refund #{$refund->id}"
            );

            Notification::create([
                'user_id' => $refund->user_id,
                'title' => 'Refund Ditolak',
                'message' => 'Pengajuan refund Anda untuk transaksi #' . $refund->transaction_id . ' ditolak. Alasan: ' . $request->admin_note,
                'type' => 'refund',
            ]);

            return response()->json(['success' => true, 'message' => 'Refund ditolak.']);
        });
    }

    public function process($id)
    {
        return DB::transaction(function () use ($id) {
            $refund = Refund::lockForUpdate()->findOrFail($id);

            if ($refund->status !== 'approved') {
                return response()->json(['success' => false, 'message' => 'Hanya refund yang disetujui yang bisa diproses.'], 400);
            }

            $oldValues = $refund->toArray();
            $refund->update([
                'status' => 'processed',
                'processed_at' => now(),
            ]);

            $this->auditService->log(
                auth()->user(),
                'refund_processed',
                'refunds',
                $refund,
                $oldValues,
                $refund->toArray(),
                "Processed refund #{$refund->id}"
            );

            $transaction = $refund->transaction;
            $transaction->update([
                'payment_status' => 'refunded'
            ]);

            // Cancel tickets
            $transaction->tickets()->update([
                'is_cancelled' => true
            ]);

            // Handle referral conversions
            $conversion = ReferralConversion::where('transaction_id', $transaction->id)->first();
            if ($conversion && $conversion->status !== 'rejected') {
                $conversion->update(['status' => 'rejected']);
                if ($conversion->reward) {
                    $conversion->reward->update(['status' => 'rejected']);
                    
                    Notification::create([
                        'user_id' => $conversion->reward->user_id,
                        'title' => 'Reward Referral Dibatalkan',
                        'message' => 'Reward dari kode referral Anda dibatalkan karena transaksi terkait telah di-refund.',
                        'type' => 'referral_rejected',
                    ]);
                }
            }

            Notification::create([
                'user_id' => $refund->user_id,
                'title' => 'Refund Selesai Diproses',
                'message' => 'Refund Anda sebesar Rp ' . number_format($refund->refund_amount, 0, ',', '.') . ' untuk transaksi #' . $transaction->id . ' telah selesai diproses.',
                'type' => 'refund',
            ]);

            return response()->json(['success' => true, 'message' => 'Refund selesai diproses dan tiket dibatalkan.']);
        });
    }
}

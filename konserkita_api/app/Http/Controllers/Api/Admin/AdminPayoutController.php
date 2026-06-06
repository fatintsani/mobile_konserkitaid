<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\OrganizerPayout;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class AdminPayoutController extends BaseController
{
    public function index()
    {
        $payouts = OrganizerPayout::with(['organizer.user', 'event', 'requester'])
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->sendResponse($payouts, 'Payouts retrieved successfully.');
    }

    public function show($id)
    {
        $payout = OrganizerPayout::with(['organizer.user', 'event', 'requester'])->find($id);

        if (!$payout) {
            return $this->sendError('Payout not found.', [], 404);
        }

        return $this->sendResponse($payout, 'Payout retrieved successfully.');
    }

    public function approve(Request $request, $id)
    {
        DB::beginTransaction();
        try {
            $payout = OrganizerPayout::lockForUpdate()->find($id);

            if (!$payout) {
                return $this->sendError('Payout not found.', [], 404);
            }

            if ($payout->status !== 'pending') {
                return $this->sendError('Only pending payouts can be approved.', [], 400);
            }

            $payout->update([
                'status' => 'approved',
                'approved_at' => now(),
            ]);

            \App\Models\Notification::create([
                'user_id' => $payout->requester->id,
                'title' => 'Payout Approved',
                'message' => 'Your payout request for Rp ' . number_format($payout->amount, 0, ',', '.') . ' has been approved and will be processed soon.',
                'type' => 'payout',
            ]);

            DB::commit();
            return $this->sendResponse($payout, 'Payout approved successfully.');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Failed to approve payout.', ['error' => $e->getMessage()], 500);
        }
    }

    public function reject(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'admin_note' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error.', $validator->errors(), 400);
        }

        DB::beginTransaction();
        try {
            $payout = OrganizerPayout::lockForUpdate()->find($id);

            if (!$payout) {
                return $this->sendError('Payout not found.', [], 404);
            }

            if ($payout->status !== 'pending') {
                return $this->sendError('Only pending payouts can be rejected.', [], 400);
            }

            $payout->update([
                'status' => 'rejected',
                'admin_note' => $request->admin_note,
            ]);

            \App\Models\Notification::create([
                'user_id' => $payout->requester->id,
                'title' => 'Payout Rejected',
                'message' => 'Your payout request for Rp ' . number_format($payout->amount, 0, ',', '.') . ' has been rejected. Reason: ' . $request->admin_note,
                'type' => 'payout',
            ]);

            DB::commit();
            return $this->sendResponse($payout, 'Payout rejected successfully.');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Failed to reject payout.', ['error' => $e->getMessage()], 500);
        }
    }

    public function markPaid(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'admin_note' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error.', $validator->errors(), 400);
        }

        DB::beginTransaction();
        try {
            $payout = OrganizerPayout::lockForUpdate()->find($id);

            if (!$payout) {
                return $this->sendError('Payout not found.', [], 404);
            }

            if ($payout->status !== 'approved') {
                return $this->sendError('Only approved payouts can be marked as paid.', [], 400);
            }

            $payout->update([
                'status' => 'paid',
                'paid_at' => now(),
                'admin_note' => $request->admin_note ?? $payout->admin_note,
            ]);

            \App\Models\Notification::create([
                'user_id' => $payout->requester->id,
                'title' => 'Payout Paid',
                'message' => 'Your payout of Rp ' . number_format($payout->amount, 0, ',', '.') . ' has been transferred to your bank account.',
                'type' => 'payout',
            ]);

            DB::commit();
            return $this->sendResponse($payout, 'Payout marked as paid successfully.');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Failed to mark payout as paid.', ['error' => $e->getMessage()], 500);
        }
    }
}

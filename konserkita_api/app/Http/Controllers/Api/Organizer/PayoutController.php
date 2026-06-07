<?php

namespace App\Http\Controllers\Api\Organizer;

use App\Http\Controllers\Api\BaseController;
use App\Models\OrganizerPayout;
use App\Models\TransactionItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class PayoutController extends BaseController
{
    private function calculateBalances($organizerId)
    {
        // Calculate gross revenue from completed/successful transactions for this organizer
        $grossRevenue = TransactionItem::whereHas('transaction', function($q) {
            $q->where('payment_status', 'success');
        })->whereHas('ticketType.event', function($q) use ($organizerId) {
            $q->where('organizer_id', $organizerId);
        })->sum('subtotal');

        $organizer = \App\Models\Organizer::find($organizerId);
        $subscription = $organizer ? $organizer->subscription()->with('plan')->first() : null;
        $platformFeePercentage = $subscription ? $subscription->plan->platform_fee_percentage : config('platform.platform_fee_percentage', 10);
        $totalPlatformFee = $grossRevenue * ($platformFeePercentage / 100);
        $netRevenue = $grossRevenue - $totalPlatformFee;

        // Calculate payouts
        $totalPaidOut = OrganizerPayout::where('organizer_id', $organizerId)
            ->where('status', 'paid')
            ->sum('amount');
            
        $totalLocked = OrganizerPayout::where('organizer_id', $organizerId)
            ->whereIn('status', ['pending', 'approved'])
            ->sum('amount');

        $availableBalance = $netRevenue - $totalPaidOut - $totalLocked;

        return [
            'gross_revenue' => (float) $grossRevenue,
            'platform_fee' => (float) $totalPlatformFee,
            'net_revenue' => (float) $netRevenue,
            'total_paid_out' => (float) $totalPaidOut,
            'total_locked' => (float) $totalLocked,
            'available_balance' => (float) $availableBalance,
        ];
    }

    public function balance(Request $request)
    {
        $organizer = $request->user()->organizer;
        if (!$organizer) {
            return $this->sendError('You are not registered as an organizer.', [], 403);
        }

        $balances = $this->calculateBalances($organizer->id);
        return $this->sendResponse($balances, 'Organizer balances retrieved successfully.');
    }

    public function index(Request $request)
    {
        $organizer = $request->user()->organizer;
        if (!$organizer) {
            return $this->sendError('You are not registered as an organizer.', [], 403);
        }

        $payouts = OrganizerPayout::where('organizer_id', $organizer->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->sendResponse($payouts, 'Payouts retrieved successfully.');
    }

    public function show(Request $request, $id)
    {
        $organizer = $request->user()->organizer;
        if (!$organizer) {
            return $this->sendError('You are not registered as an organizer.', [], 403);
        }

        $payout = OrganizerPayout::where('organizer_id', $organizer->id)->find($id);

        if (!$payout) {
            return $this->sendError('Payout not found.', [], 404);
        }

        return $this->sendResponse($payout, 'Payout retrieved successfully.');
    }

    public function store(Request $request)
    {
        $organizer = $request->user()->organizer;
        if (!$organizer) {
            return $this->sendError('You are not registered as an organizer.', [], 403);
        }

        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:10000',
            'bank_name' => 'required|string',
            'bank_account_name' => 'required|string',
            'bank_account_number' => 'required|string',
            'event_id' => 'nullable|exists:events,id',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error.', $validator->errors(), 400);
        }

        // Verify event belongs to organizer if provided
        if ($request->filled('event_id')) {
            $event = \App\Models\Event::where('id', $request->event_id)->where('organizer_id', $organizer->id)->first();
            if (!$event) {
                return $this->sendError('Event not found or does not belong to you.', [], 403);
            }
        }

        DB::beginTransaction();
        try {
            // Lock payouts to prevent concurrent requests overdrawing balance
            OrganizerPayout::where('organizer_id', $organizer->id)->lockForUpdate()->get();

            $balances = $this->calculateBalances($organizer->id);
            $requestedAmount = (float) $request->amount;

            if ($requestedAmount > $balances['available_balance']) {
                DB::rollBack();
                return $this->sendError('Insufficient available balance.', [
                    'available_balance' => $balances['available_balance'],
                    'requested_amount' => $requestedAmount
                ], 400);
            }

            $payout = OrganizerPayout::create([
                'organizer_id' => $organizer->id,
                'event_id' => $request->event_id,
                'requested_by' => $request->user()->id,
                'amount' => $requestedAmount,
                'platform_fee' => 0, // Fee is already deducted globally to get available balance
                'net_amount' => $requestedAmount,
                'bank_name' => $request->bank_name,
                'bank_account_name' => $request->bank_account_name,
                'bank_account_number' => $request->bank_account_number,
                'status' => 'pending',
                'requested_at' => now(),
            ]);

            \App\Models\Notification::create([
                'user_id' => $request->user()->id,
                'title' => 'Payout Request Submitted',
                'message' => 'Your payout request for Rp ' . number_format($requestedAmount, 0, ',', '.') . ' has been submitted and is pending approval.',
                'type' => 'payout',
            ]);

            DB::commit();

            return $this->sendResponse($payout, 'Payout request submitted successfully.');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Failed to process payout request.', ['error' => $e->getMessage()], 500);
        }
    }
}

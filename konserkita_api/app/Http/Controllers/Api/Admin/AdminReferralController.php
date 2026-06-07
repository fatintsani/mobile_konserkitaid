<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ReferralCode;
use App\Models\ReferralConversion;
use App\Models\ReferralReward;
use Illuminate\Http\Request;

class AdminReferralController extends Controller
{
    public function codes(Request $request)
    {
        $codes = ReferralCode::with('user')->withCount('conversions')->latest()->paginate(15);
        return response()->json(['success' => true, 'data' => $codes]);
    }

    public function conversions(Request $request)
    {
        $conversions = ReferralConversion::with(['referralCode.user', 'referredUser', 'transaction'])
            ->latest()
            ->paginate(15);
        return response()->json(['success' => true, 'data' => $conversions]);
    }

    public function rewards(Request $request)
    {
        $query = ReferralReward::with(['user', 'conversion.transaction'])->latest();
        
        if ($request->has('status') && $request->status !== '') {
            $query->where('status', $request->status);
        }

        $rewards = $query->paginate(15);
        return response()->json(['success' => true, 'data' => $rewards]);
    }

    public function approveReward($id)
    {
        $reward = ReferralReward::findOrFail($id);
        
        if ($reward->status !== 'pending') {
            return response()->json(['success' => false, 'message' => 'Hanya reward pending yang bisa disetujui.'], 400);
        }

        $reward->update(['status' => 'approved']);
        $reward->conversion()->update(['status' => 'approved']);

        return response()->json(['success' => true, 'message' => 'Reward disetujui.']);
    }

    public function rejectReward($id)
    {
        $reward = ReferralReward::findOrFail($id);
        
        if ($reward->status !== 'pending') {
            return response()->json(['success' => false, 'message' => 'Hanya reward pending yang bisa ditolak.'], 400);
        }

        $reward->update(['status' => 'rejected']);
        $reward->conversion()->update(['status' => 'rejected']);

        return response()->json(['success' => true, 'message' => 'Reward ditolak.']);
    }

    public function markPaid($id)
    {
        $reward = ReferralReward::findOrFail($id);
        
        if ($reward->status !== 'approved') {
            return response()->json(['success' => false, 'message' => 'Hanya reward yang disetujui yang bisa ditandai sebagai dibayar.'], 400);
        }

        $reward->update(['status' => 'paid', 'paid_at' => now()]);
        $reward->conversion()->update(['status' => 'paid']);

        return response()->json(['success' => true, 'message' => 'Reward ditandai sebagai dibayar.']);
    }

    public function stats()
    {
        $totalConversions = ReferralConversion::count();
        $pendingCommission = ReferralReward::where('status', 'pending')->sum('amount');
        $paidCommission = ReferralReward::where('status', 'paid')->sum('amount');
        $topReferrers = ReferralCode::with('user')
            ->orderByDesc('used_count')
            ->take(5)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'total_conversions' => $totalConversions,
                'pending_commission' => $pendingCommission,
                'paid_commission' => $paidCommission,
                'top_referrers' => $topReferrers,
            ]
        ]);
    }
}

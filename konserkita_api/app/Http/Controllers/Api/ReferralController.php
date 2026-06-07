<?php

namespace App\Http\Controllers\Api;

use App\Models\ReferralCode;
use App\Models\ReferralClick;
use App\Models\ReferralConversion;
use App\Models\ReferralReward;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ReferralController extends BaseController
{
    public function myCode(Request $request)
    {
        $user = $request->user();
        
        $code = ReferralCode::where('user_id', $user->id)
            ->where('type', 'user_referral')
            ->first();

        if (!$code) {
            $codeStr = strtoupper(substr($user->name, 0, 3)) . rand(1000, 9999);
            // Ensure unique
            while (ReferralCode::where('code', $codeStr)->exists()) {
                $codeStr = strtoupper(substr($user->name, 0, 3)) . rand(1000, 9999);
            }

            $code = ReferralCode::create([
                'user_id' => $user->id,
                'code' => $codeStr,
                'type' => 'user_referral',
                'status' => 'active',
                'commission_type' => 'percentage', // Default for users
                'commission_value' => 5, // 5% commission
            ]);
        }

        return $this->sendResponse($code, 'Referral code retrieved.');
    }

    public function rewards(Request $request)
    {
        $rewards = ReferralReward::with('conversion.transaction')
            ->where('user_id', $request->user()->id)
            ->latest()
            ->paginate(10);

        return $this->sendResponse($rewards, 'Rewards retrieved.');
    }

    public function conversions(Request $request)
    {
        // First get the user's referral code ids
        $codeIds = ReferralCode::where('user_id', $request->user()->id)->pluck('id');

        $conversions = ReferralConversion::with('transaction')
            ->whereIn('referral_code_id', $codeIds)
            ->latest()
            ->paginate(10);

        return $this->sendResponse($conversions, 'Conversions retrieved.');
    }

    public function trackClick(Request $request)
    {
        $request->validate([
            'code' => 'required|string|exists:referral_codes,code'
        ]);

        $code = ReferralCode::where('code', $request->code)->first();

        if ($code) {
            ReferralClick::create([
                'referral_code_id' => $code->id,
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
            ]);
        }

        return $this->sendResponse(null, 'Click tracked.');
    }

    public function apply(Request $request)
    {
        $request->validate([
            'code' => 'required|string'
        ]);

        $code = ReferralCode::where('code', $request->code)->first();

        if (!$code) {
            return $this->sendError('Invalid referral code.', [], 400);
        }

        if ($code->status !== 'active') {
            return $this->sendError('Referral code is inactive.', [], 400);
        }

        if ($code->expired_at && $code->expired_at->isPast()) {
            return $this->sendError('Referral code has expired.', [], 400);
        }

        if ($code->usage_limit && $code->used_count >= $code->usage_limit) {
            return $this->sendError('Referral code usage limit reached.', [], 400);
        }

        // Cannot use own code
        if ($request->user() && $code->user_id === $request->user()->id) {
            return $this->sendError('You cannot use your own referral code.', [], 400);
        }

        return $this->sendResponse([
            'code' => $code->code,
            'type' => $code->type,
            'commission_type' => $code->commission_type,
            'commission_value' => $code->commission_value,
        ], 'Referral code applied successfully.');
    }
}

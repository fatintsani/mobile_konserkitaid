<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\BaseController as BaseController;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\AccountRecoveryRequest;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;
use App\Services\SecurityService;
use App\Notifications\PasswordResetNotification;
use App\Notifications\PasswordChangedNotification;
use App\Notifications\TwoFactorResetRequestedNotification;

class AccountRecoveryController extends BaseController
{
    protected $securityService;

    public function __construct(SecurityService $securityService)
    {
        $this->securityService = $securityService;
    }

    public function forgotPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        // Always return a neutral response to prevent email enumeration
        $responseMessage = 'Jika email terdaftar, instruksi reset password telah dikirim.';

        if ($user) {
            $token = Str::random(64);

            AccountRecoveryRequest::create([
                'user_id' => $user->id,
                'email' => $user->email,
                'type' => AccountRecoveryRequest::TYPE_PASSWORD_RESET,
                'token_hash' => Hash::make($token),
                'expires_at' => now()->addMinutes(15),
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
            ]);

            // Fire notification containing the plaintext token
            $user->notify(new PasswordResetNotification($token, $user->email));
        }

        return $this->sendResponse(null, $responseMessage);
    }

    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'token' => 'required|string',
            'password' => 'required|min:8|confirmed',
        ]);

        $recoveryRequest = AccountRecoveryRequest::where('email', $request->email)
            ->where('type', AccountRecoveryRequest::TYPE_PASSWORD_RESET)
            ->where('status', AccountRecoveryRequest::STATUS_PENDING)
            ->where('expires_at', '>', now())
            ->latest()
            ->first();

        if (!$recoveryRequest || !Hash::check($request->token, $recoveryRequest->token_hash)) {
            return $this->sendError('Invalid or expired token.', [], 400);
        }

        $user = User::where('email', $request->email)->first();
        if (!$user) {
            return $this->sendError('User not found.', [], 404);
        }

        // Update password
        $user->password = Hash::make($request->password);
        $user->save();

        // Revoke all existing sessions (Sanctum tokens & UserSessions)
        $user->tokens()->delete();
        $user->sessions()->update(['revoked_at' => now()]);

        // Complete recovery request
        $recoveryRequest->update([
            'status' => AccountRecoveryRequest::STATUS_COMPLETED,
            'completed_at' => now(),
        ]);

        // Log activity and create alert
        $this->securityService->logActivity($user, 'password_changed', $request);
        $this->securityService->createAlert(
            $user,
            'password_changed',
            'critical',
            'Password Reset',
            'Your account password was just changed.',
            $request
        );

        $user->notify(new PasswordChangedNotification());

        return $this->sendResponse(null, 'Password successfully reset.');
    }

    public function requestTwoFactorReset(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return $this->sendError('User not found.', [], 404);
        }

        if (!$user->two_factor_enabled) {
            return $this->sendError('Two-factor authentication is not enabled on this account.', [], 400);
        }

        $existingPending = AccountRecoveryRequest::where('user_id', $user->id)
            ->where('type', AccountRecoveryRequest::TYPE_TWO_FACTOR_RESET)
            ->where('status', AccountRecoveryRequest::STATUS_PENDING)
            ->first();

        if ($existingPending) {
            return $this->sendError('You already have a pending two-factor reset request.', [], 400);
        }

        $recovery = AccountRecoveryRequest::create([
            'user_id' => $user->id,
            'email' => $user->email,
            'type' => AccountRecoveryRequest::TYPE_TWO_FACTOR_RESET,
            'expires_at' => now()->addDays(7), // Wait up to 7 days for admin review
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        $user->notify(new TwoFactorResetRequestedNotification());

        return $this->sendResponse($recovery, 'Two-factor reset request submitted successfully.');
    }

    public function getRecoveryRequests(Request $request)
    {
        $user = $request->user();
        $requests = AccountRecoveryRequest::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->sendResponse($requests, 'Recovery requests retrieved.');
    }
}

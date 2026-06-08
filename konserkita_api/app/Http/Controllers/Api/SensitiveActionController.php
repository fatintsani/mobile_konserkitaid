<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\BaseController as BaseController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use App\Models\Passkey;
use PragmaRX\Google2FA\Google2FA;

class SensitiveActionController extends BaseController
{
    /**
     * Generate a temporary token valid for 10 minutes for sensitive actions
     */
    private function generateConfirmationToken($user)
    {
        $token = Str::random(40);
        Cache::put('sensitive_action_token_' . $user->id, $token, now()->addMinutes(10));
        return $token;
    }

    public function confirmPassword(Request $request)
    {
        $request->validate([
            'password' => 'required|string',
        ]);

        $user = $request->user();

        if (!Hash::check($request->password, $user->password)) {
            return $this->sendError('Incorrect password.', [], 400);
        }

        $token = $this->generateConfirmationToken($user);

        return $this->sendResponse(['confirmation_token' => $token], 'Password confirmed.');
    }

    public function confirm2Fa(Request $request)
    {
        $request->validate([
            'code' => 'required|string',
        ]);

        $user = $request->user();

        if (!$user->two_factor_enabled || !$user->two_factor_secret) {
            return $this->sendError('Two-factor authentication is not enabled.', [], 400);
        }

        $google2fa = new Google2FA();
        $valid = $google2fa->verifyKey($user->two_factor_secret, $request->code);

        if (!$valid) {
            return $this->sendError('Invalid 2FA code.', [], 400);
        }

        $token = $this->generateConfirmationToken($user);

        return $this->sendResponse(['confirmation_token' => $token], '2FA confirmed.');
    }

    // We can also add passkey confirmation here if the mobile app supports signing a challenge for re-auth
    // For now, confirmPassword and confirm2Fa are the primary methods.
}

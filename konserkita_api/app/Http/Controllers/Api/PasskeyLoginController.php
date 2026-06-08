<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use LaravelWebauthn\Facades\Webauthn;
use App\Models\User;
use App\Models\AuditLog;
use LaravelWebauthn\Models\WebauthnKey;

class PasskeyLoginController extends Controller
{
    public function options(Request $request)
    {
        $user = null;
        if ($request->has('email')) {
            $user = User::where('email', $request->email)->first();
            if (!$user) {
                return response()->json(['message' => 'User not found'], 404);
            }
        }
        
        $publicKey = Webauthn::prepareAssertion($user);
        return response()->json($publicKey);
    }

    public function verify(Request $request)
    {
        $user = null;
        if ($request->has('email')) {
            $user = User::where('email', $request->email)->first();
        } else {
            // Find user from the passkey ID if userless
            $credentialId = \Webauthn\Util\Base64::decode($request->input('id', ''));
            $passkey = \App\Models\Passkey::where('credentialId', $credentialId)->first();
            if ($passkey) {
                $user = User::find($passkey->user_id);
            }
        }

        if (!$user) {
            return response()->json(['message' => 'User not found or passkey not recognized'], 404);
        }

        try {
            $isValid = Webauthn::validateAssertion($user, $request->only(['id', 'rawId', 'response', 'type']));
            
            if ($isValid) {
                // Update last_used_at
                $credentialId = \Webauthn\Util\Base64::decode($request->input('id', ''));
                \App\Models\Passkey::where('credentialId', $credentialId)->update(['last_used_at' => now()]);

                // Create token
                $token = $user->createToken('passkey-login')->plainTextToken;

                AuditLog::create([
                    'user_id' => $user->id,
                    'action' => 'passkey_login_success',
                    'details' => 'Logged in using passkey',
                    'ip_address' => $request->ip(),
                ]);

                return response()->json([
                    'message' => 'Login successful',
                    'user' => $user,
                    'token' => $token,
                ]);
            }
        } catch (\Exception $e) {
            AuditLog::create([
                'user_id' => $user->id ?? null,
                'action' => 'passkey_login_failed',
                'details' => $e->getMessage(),
                'ip_address' => $request->ip(),
            ]);

            return response()->json(['message' => 'Invalid passkey', 'error' => $e->getMessage()], 401);
        }

        AuditLog::create([
            'user_id' => $user->id ?? null,
            'action' => 'passkey_login_failed',
            'details' => 'Assertion validation failed',
            'ip_address' => $request->ip(),
        ]);

        return response()->json(['message' => 'Invalid passkey'], 401);
    }
}

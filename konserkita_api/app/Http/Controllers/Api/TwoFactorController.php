<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use PragmaRX\Google2FA\Google2FA;
use BaconQrCode\Renderer\ImageRenderer;
use BaconQrCode\Renderer\Image\SvgImageBackEnd;
use BaconQrCode\Renderer\RendererStyle\RendererStyle;
use BaconQrCode\Writer;
use App\Models\AuditLog;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;

class TwoFactorController extends Controller
{
    public function setup(Request $request)
    {
        $user = $request->user();
        $google2fa = app('pragmarx.google2fa');

        if (!$user->two_factor_secret) {
            $user->two_factor_secret = $google2fa->generateSecretKey();
            $user->save();
        }

        $qrCodeUrl = $google2fa->getQRCodeUrl(
            config('app.name'),
            $user->email,
            $user->two_factor_secret
        );

        $renderer = new ImageRenderer(
            new RendererStyle(200),
            new SvgImageBackEnd()
        );
        $writer = new Writer($renderer);
        $svg = $writer->writeString($qrCodeUrl);
        $base64Svg = base64_encode($svg);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => '2fa_setup_started',
            'details' => 'User started 2FA setup',
            'ip_address' => $request->ip(),
        ]);

        return response()->json([
            'secret' => $user->two_factor_secret,
            'qr_code_svg' => 'data:image/svg+xml;base64,' . $base64Svg,
        ]);
    }

    public function confirm(Request $request)
    {
        $request->validate(['code' => 'required|string']);
        $user = $request->user();
        $google2fa = app('pragmarx.google2fa');

        $valid = $google2fa->verifyKey($user->two_factor_secret, $request->code);

        if ($valid) {
            $user->two_factor_enabled = true;
            $user->two_factor_confirmed_at = now();
            $user->save();

            // Generate recovery codes
            $user->twoFactorRecoveryCodes()->delete(); // delete old ones if any
            $recoveryCodes = [];
            for ($i = 0; $i < 8; $i++) {
                $code = Str::random(10) . '-' . Str::random(10);
                $recoveryCodes[] = $code;
                $user->twoFactorRecoveryCodes()->create([
                    'code_hash' => Hash::make($code),
                ]);
            }

            AuditLog::create([
                'user_id' => $user->id,
                'action' => '2fa_enabled',
                'details' => 'User successfully enabled 2FA',
                'ip_address' => $request->ip(),
            ]);

            return response()->json([
                'message' => '2FA enabled successfully',
                'recovery_codes' => $recoveryCodes,
            ]);
        }

        return response()->json(['message' => 'Invalid confirmation code'], 400);
    }

    public function disable(Request $request)
    {
        $user = $request->user();
        $user->two_factor_enabled = false;
        $user->two_factor_secret = null;
        $user->two_factor_confirmed_at = null;
        $user->save();

        $user->twoFactorRecoveryCodes()->delete();

        AuditLog::create([
            'user_id' => $user->id,
            'action' => '2fa_disabled',
            'details' => 'User disabled 2FA',
            'ip_address' => $request->ip(),
        ]);

        return response()->json(['message' => '2FA disabled successfully']);
    }

    public function getRecoveryCodes(Request $request)
    {
        // For security, recovery codes shouldn't be viewable again after setup.
        // We allow regenerating them instead.
        return $this->regenerateRecoveryCodes($request);
    }

    public function regenerateRecoveryCodes(Request $request)
    {
        $user = $request->user();
        
        $user->twoFactorRecoveryCodes()->delete();
        $recoveryCodes = [];
        for ($i = 0; $i < 8; $i++) {
            $code = Str::random(10) . '-' . Str::random(10);
            $recoveryCodes[] = $code;
            $user->twoFactorRecoveryCodes()->create([
                'code_hash' => Hash::make($code),
            ]);
        }

        return response()->json([
            'message' => 'Recovery codes regenerated',
            'recovery_codes' => $recoveryCodes,
        ]);
    }

    public function challenge(Request $request)
    {
        $request->validate([
            'temporary_token' => 'required|string',
        ]);

        $accessToken = PersonalAccessToken::findToken($request->temporary_token);

        if (!$accessToken || !$accessToken->can('2fa_challenge')) {
            return response()->json(['message' => 'Invalid or expired temporary token'], 401);
        }

        $user = $accessToken->tokenable;

        $valid = false;

        if ($request->has('code')) {
            $google2fa = app('pragmarx.google2fa');
            $valid = $google2fa->verifyKey($user->two_factor_secret, $request->code);
        } elseif ($request->has('recovery_code')) {
            $recoveryCodeStr = $request->recovery_code;
            $ununsedCodes = $user->twoFactorRecoveryCodes()->whereNull('used_at')->get();
            foreach ($ununsedCodes as $code) {
                if (Hash::check($recoveryCodeStr, $code->code_hash)) {
                    $valid = true;
                    $code->used_at = now();
                    $code->save();

                    AuditLog::create([
                        'user_id' => $user->id,
                        'action' => 'recovery_code_used',
                        'details' => 'Used a recovery code',
                        'ip_address' => $request->ip(),
                    ]);
                    break;
                }
            }
        }

        if ($valid) {
            $accessToken->delete(); // Revoke temporary token

            $token = $user->createToken('KonserKitaApp')->plainTextToken;
            
            if ($user->role === 'organizer') {
                $user->load('organizer');
            }

            AuditLog::create([
                'user_id' => $user->id,
                'action' => '2fa_challenge_success',
                'details' => 'Successfully passed 2FA challenge',
                'ip_address' => $request->ip(),
            ]);

            return response()->json([
                'message' => 'Login successful',
                'user' => $user,
                'token' => $token,
            ]);
        }

        AuditLog::create([
            'user_id' => $user->id,
            'action' => '2fa_challenge_failed',
            'details' => 'Failed 2FA challenge',
            'ip_address' => $request->ip(),
        ]);

        return response()->json(['message' => 'Invalid code'], 400);
    }
}

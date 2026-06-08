<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use LaravelWebauthn\Facades\Webauthn;
use App\Models\AuditLog;

class PasskeyRegisterController extends Controller
{
    public function options(Request $request)
    {
        $user = $request->user();
        $publicKey = Webauthn::prepareAttestation($user);

        return response()->json($publicKey);
    }

    public function verify(Request $request)
    {
        $user = $request->user();
        $keyName = $request->input('name', 'My Passkey');
        
        try {
            $webauthnKey = Webauthn::validateAttestation($user, $request->only(['id', 'rawId', 'response', 'type']), $keyName);
            
            AuditLog::create([
                'user_id' => $user->id,
                'action' => 'passkey_registered',
                'details' => 'Registered a new passkey: ' . $keyName,
                'ip_address' => $request->ip(),
            ]);

            return response()->json([
                'message' => 'Passkey registered successfully',
                'passkey' => $webauthnKey
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Failed to register passkey', 'error' => $e->getMessage()], 400);
        }
    }
}

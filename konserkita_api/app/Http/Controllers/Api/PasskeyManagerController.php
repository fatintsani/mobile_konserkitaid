<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Passkey;
use App\Models\AuditLog;
use App\Services\SecurityService;

class PasskeyManagerController extends Controller
{
    protected $securityService;

    public function __construct(SecurityService $securityService)
    {
        $this->securityService = $securityService;
    }
    public function index(Request $request)
    {
        $user = $request->user();
        $passkeys = Passkey::where('user_id', $user->id)
            ->select('id', 'name', 'created_at', 'last_used_at')
            ->get();
            
        return response()->json($passkeys);
    }

    public function destroy(Request $request, $id)
    {
        $request->validate([
            'confirmation_token' => 'required|string',
        ]);

        $user = $request->user();

        if (!$this->securityService->validateConfirmationToken($user, $request->confirmation_token)) {
            return response()->json(['message' => 'Invalid or expired confirmation token.'], 403);
        }

        $passkey = Passkey::where('id', $id)->where('user_id', $user->id)->first();
        
        if (!$passkey) {
            return response()->json(['message' => 'Passkey not found'], 404);
        }
        
        $passkey->delete();
        
        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'passkey_deleted',
            'details' => 'Deleted passkey: ' . $passkey->name,
            'ip_address' => $request->ip(),
        ]);

        return response()->json(['message' => 'Passkey deleted successfully']);
    }
}

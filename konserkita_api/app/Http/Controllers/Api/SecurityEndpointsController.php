<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\UserSession;
use App\Models\LoginActivity;
use App\Services\SecurityService;

class SecurityEndpointsController extends Controller
{
    protected $securityService;

    public function __construct(SecurityService $securityService)
    {
        $this->securityService = $securityService;
    }

    public function getSessions(Request $request)
    {
        $user = $request->user();
        $sessions = UserSession::where('user_id', $user->id)
            ->whereNull('revoked_at')
            ->orderBy('last_active_at', 'desc')
            ->get();

        // Mark current session
        $currentTokenId = $user->currentAccessToken()->id;
        $sessions->transform(function ($session) use ($currentTokenId) {
            $session->is_current_device = ($session->token_id === $currentTokenId);
            return $session;
        });

        return response()->json($sessions);
    }

    public function revokeSession(Request $request, $id)
    {
        $user = $request->user();
        $session = UserSession::where('id', $id)->where('user_id', $user->id)->first();

        if (!$session) {
            return response()->json(['message' => 'Session not found'], 404);
        }

        // Revoke sanctum token
        if ($session->token_id) {
            $user->tokens()->where('id', $session->token_id)->delete();
        }

        $session->delete(); // Or $session->update(['revoked_at' => now()]);

        $this->securityService->logActivity($request, 'session_revoked', $user, null, [
            'revoked_session_id' => $session->id,
            'revoked_device' => $session->device_name,
        ]);

        return response()->json(['message' => 'Session revoked successfully']);
    }

    public function revokeOtherSessions(Request $request)
    {
        $user = $request->user();
        $currentTokenId = $user->currentAccessToken()->id;

        // Delete other sanctum tokens
        $user->tokens()->where('id', '!=', $currentTokenId)->delete();

        // Delete other user sessions
        UserSession::where('user_id', $user->id)
            ->where('token_id', '!=', $currentTokenId)
            ->delete();

        $this->securityService->logActivity($request, 'session_revoked', $user, null, [
            'type' => 'revoke_others'
        ]);

        return response()->json(['message' => 'Other sessions revoked successfully']);
    }

    public function getLoginActivities(Request $request)
    {
        $user = $request->user();
        $activities = LoginActivity::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($activities);
    }
}

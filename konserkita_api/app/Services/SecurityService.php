<?php

namespace App\Services;

use App\Models\LoginActivity;
use App\Models\UserSession;
use Illuminate\Http\Request;
use Jenssegers\Agent\Agent; // If available, otherwise we'll parse user-agent manually.

class SecurityService
{
    /**
     * Log a login activity
     */
    public function logActivity(Request $request, $eventType, $user = null, $email = null, array $metadata = [])
    {
        $platform = $this->getPlatform($request);

        LoginActivity::create([
            'user_id' => $user ? $user->id : null,
            'email' => $email ?? ($user ? $user->email : null),
            'event_type' => $eventType,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'platform' => $platform,
            'metadata' => empty($metadata) ? null : $metadata,
        ]);
    }

    /**
     * Create a user session record and link it to a sanctum token
     */
    public function createSession(Request $request, $user, $tokenId)
    {
        $platform = $this->getPlatform($request);
        $browser = $this->getBrowser($request);
        
        // You could also map IP to location using a GeoIP service here, but we will leave it as device_name for now.
        $deviceName = $platform . ' - ' . $browser;

        return UserSession::create([
            'user_id' => $user->id,
            'token_id' => $tokenId,
            'device_name' => $deviceName,
            'platform' => $platform,
            'browser' => $browser,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'last_active_at' => now(),
        ]);
    }

    private function getPlatform(Request $request)
    {
        $userAgent = strtolower($request->userAgent() ?? '');
        
        if (str_contains($userAgent, 'android')) {
            return 'Android';
        } elseif (str_contains($userAgent, 'iphone') || str_contains($userAgent, 'ipad')) {
            return 'iOS';
        } elseif (str_contains($userAgent, 'windows')) {
            return 'Windows';
        } elseif (str_contains($userAgent, 'mac')) {
            return 'macOS';
        } elseif (str_contains($userAgent, 'linux')) {
            return 'Linux';
        }

        return 'Unknown';
    }

    private function getBrowser(Request $request)
    {
        $userAgent = strtolower($request->userAgent() ?? '');

        if (str_contains($userAgent, 'edg')) {
            return 'Edge';
        } elseif (str_contains($userAgent, 'chrome')) {
            return 'Chrome';
        } elseif (str_contains($userAgent, 'safari') && !str_contains($userAgent, 'chrome')) {
            return 'Safari';
        } elseif (str_contains($userAgent, 'firefox')) {
            return 'Firefox';
        } elseif (str_contains($userAgent, 'dart')) {
            return 'Flutter App';
        }

        return 'Unknown';
    }
}

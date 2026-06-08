<?php

namespace App\Services;

use App\Models\LoginActivity;
use App\Models\UserSession;
use App\Models\AccountLock;
use App\Models\SecurityAlert;
use Illuminate\Http\Request;

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

    /**
     * Check if an account is locked. Returns the lock object or null.
     */
    public function checkLock($email)
    {
        if (!$email) return null;
        
        return AccountLock::where('email', $email)
            ->where(function($query) {
                $query->where('locked_until', '>', now())
                      ->orWhereNull('locked_until');
            })
            ->whereNull('unlocked_at')
            ->first();
    }

    /**
     * Handle a failed login attempt: log it, and lock account if needed.
     */
    public function handleFailedLogin(Request $request, $email)
    {
        $this->logActivity($request, 'login_failed', null, $email);

        if (!$email) return;

        $failures = LoginActivity::where('email', $email)
            ->where('event_type', 'login_failed')
            ->where('created_at', '>=', now()->subMinutes(10))
            ->count();

        if ($failures >= 5) {
            // Lock if not already locked
            if (!$this->checkLock($email)) {
                $user = \App\Models\User::where('email', $email)->first();
                
                AccountLock::create([
                    'user_id' => $user ? $user->id : null,
                    'email' => $email,
                    'reason' => 'too_many_failed_logins',
                    'locked_until' => now()->addMinutes(15),
                ]);

                $this->createAlert(
                    $user,
                    $email,
                    'account_locked',
                    'critical',
                    'Account Locked',
                    'Your account has been temporarily locked due to multiple failed login attempts.',
                    $request
                );
            }
        }
    }

    /**
     * Detect if this login is suspicious before creating the session.
     */
    public function detectSuspiciousLogin(Request $request, $user)
    {
        $currentIp = $request->ip();
        $previousIps = UserSession::where('user_id', $user->id)
            ->pluck('ip_address')
            ->filter()
            ->unique()
            ->toArray();
            
        if (!empty($previousIps) && !in_array($currentIp, $previousIps)) {
            $this->createAlert(
                $user,
                $user->email,
                'unusual_ip',
                'medium',
                'Unusual IP Login',
                'A login was detected from a new IP address: ' . $currentIp,
                $request
            );
        }

        $platform = $this->getPlatform($request);
        $browser = $this->getBrowser($request);
        $deviceName = $platform . ' - ' . $browser;
        
        $previousDevices = UserSession::where('user_id', $user->id)
            ->pluck('device_name')
            ->filter()
            ->unique()
            ->toArray();
            
        if (!empty($previousDevices) && !in_array($deviceName, $previousDevices)) {
            $this->createAlert(
                $user,
                $user->email,
                'new_device_login',
                'low',
                'New Device Login',
                'A login was detected from a new device: ' . $deviceName,
                $request
            );
        }
    }

    /**
     * Create a security alert and optionally dispatch notification.
     */
    public function createAlert($user, $email, $type, $severity, $title, $message, $request = null)
    {
        $alert = SecurityAlert::create([
            'user_id' => $user ? $user->id : null,
            'email' => $email,
            'type' => $type,
            'severity' => $severity,
            'title' => $title,
            'message' => $message,
            'ip_address' => $request ? $request->ip() : null,
            'user_agent' => $request ? $request->userAgent() : null,
        ]);

        if ($user && in_array($severity, ['high', 'critical'])) {
            // Notification logic can be injected here
            $user->notify(new \App\Notifications\SecurityAlertNotification($alert));
        }

        return $alert;
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

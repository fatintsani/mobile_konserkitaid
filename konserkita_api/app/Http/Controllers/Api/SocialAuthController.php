<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Laravel\Socialite\Facades\Socialite;
use Exception;
use App\Services\SecurityService;

class SocialAuthController extends Controller
{
    protected $securityService;

    public function __construct(SecurityService $securityService)
    {
        $this->securityService = $securityService;
    }
    /**
     * Handle social login (Google/Microsoft).
     *
     * @param Request $request
     * @param string $provider
     * @return \Illuminate\Http\JsonResponse
     */
    public function login(Request $request, string $provider)
    {
        $request->validate([
            'access_token' => 'required|string',
        ]);

        if (!in_array($provider, ['google', 'microsoft'])) {
            return response()->json(['message' => 'Invalid provider'], 400);
        }

        try {
            // Get user from provider using the access token
            $socialUser = Socialite::driver($provider)->stateless()->userFromToken($request->access_token);

            // Find user by provider_id or email
            $user = User::where('provider_id', $socialUser->getId())
                ->orWhere('email', $socialUser->getEmail())
                ->first();

            if ($user) {
                // If user exists, link the social account
                $user->update([
                    'provider' => $provider,
                    'provider_id' => $socialUser->getId(),
                    'email_verified_at' => $user->email_verified_at ?? now(),
                ]);
                
                // if avatar is null, update it
                if ($socialUser->getAvatar() && str_contains($user->avatar, 'default_img.png')) {
                     // Since avatar is an attribute cast in User model, we might need to set it directly if it was truly null in DB
                     // Actually let's just leave avatar as is for existing users to prevent overwriting their custom avatars
                }
            } else {
                // Create a new user if one doesn't exist
                $user = User::create([
                    'name' => $socialUser->getName() ?? 'User',
                    'email' => $socialUser->getEmail(),
                    'password' => bcrypt(str()->random(16)), // Random password
                    'role' => 'customer',
                    'provider' => $provider,
                    'provider_id' => $socialUser->getId(),
                    'avatar' => $socialUser->getAvatar(),
                    'email_verified_at' => now(),
                ]);
            }

            // Create token for the user
            if ($user->two_factor_enabled) {
                $token = $user->createToken('auth_token_2fa', ['2fa_challenge'])->plainTextToken;
                return response()->json([
                    'success' => true,
                    'requires_2fa' => true,
                    'temporary_token' => $token
                ], 200);
            }

            $tokenResult = $user->createToken('auth_token');
            $token = $tokenResult->plainTextToken;

            $this->securityService->createSession($request, $user, $tokenResult->accessToken->id);
            $this->securityService->logActivity($request, 'login_success', $user, null, ['provider' => $provider]);

            return response()->json([
                'success' => true,
                'data' => [
                    'user' => $user,
                    'token' => $token,
                ],
                'message' => 'Successfully logged in with ' . ucfirst($provider),
            ], 200);

        } catch (Exception $e) {
            $this->securityService->logActivity($request, 'login_failed', null, null, ['provider' => $provider, 'error' => $e->getMessage()]);
            return response()->json([
                'message' => 'Failed to authenticate with ' . ucfirst($provider),
                'error' => $e->getMessage(),
            ], 401);
        }
    }
}

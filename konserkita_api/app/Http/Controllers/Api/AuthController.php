<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use App\Services\SecurityService;

class AuthController extends BaseController
{
    protected $securityService;

    public function __construct(SecurityService $securityService)
    {
        $this->securityService = $securityService;
    }
    public function register(\App\Http\Requests\Auth\RegisterRequest $request)
    {
        $input = $request->validated();
        $input['password'] = Hash::make($input['password']);
        $input['role'] = $input['role'] ?? 'customer';
        
        $user = User::create($input);
        
        if ($input['role'] === 'organizer') {
            $organizer = $user->organizer()->create([
                'company_name' => $user->name,
            ]);

            // Assign Trial Plan if exists
            $trialPlan = \App\Models\SubscriptionPlan::where('slug', 'trial')->first();
            if ($trialPlan) {
                $organizer->subscription()->create([
                    'subscription_plan_id' => $trialPlan->id,
                    'status' => 'trialing',
                    'starts_at' => now(),
                    'trial_ends_at' => now()->addDays(14),
                ]);
            }
        }
        
        $success['token'] =  $user->createToken('KonserKitaApp')->plainTextToken;
        $success['user'] =  $user;

        return $this->sendResponse($success, __('messages.login_success'));
    }

    public function login(\App\Http\Requests\Auth\LoginRequest $request)
    {
        $lock = $this->securityService->checkLock($request->email);
        if ($lock) {
            return $this->sendError(__('messages.unauthorized'), ['error' => 'Account is temporarily locked.'], 423);
        }

        if(Auth::attempt(['email' => $request->email, 'password' => $request->password])){ 
            $user = Auth::user(); 

            if ($user->two_factor_enabled) {
                $tempToken = $user->createToken('KonserKitaApp-2FA', ['2fa_challenge'])->plainTextToken;
                return response()->json([
                    'requires_2fa' => true,
                    'temporary_token' => $tempToken
                ]);
            }

            $tokenResult = $user->createToken('KonserKitaApp');
            $success['token'] = $tokenResult->plainTextToken;
            $success['user'] =  $user;

            $this->securityService->detectSuspiciousLogin($request, $user);
            $this->securityService->createSession($request, $user, $tokenResult->accessToken->id);
            $this->securityService->logActivity($request, 'login_success', $user);
            
            if ($user->role === 'organizer') {
                $user->load('organizer');
                $success['user'] = $user;
            }

            return $this->sendResponse($success, __('messages.login_success'));
        } 
        else{ 
            // Log failed attempt
            $this->securityService->handleFailedLogin($request, $request->email);
            return $this->sendError(__('messages.unauthorized'), ['error'=>__('messages.unauthorized')], 401);
        } 
    }

    public function profile(Request $request)
    {
        $user = $request->user();
        if ($user->role === 'organizer') {
            $user->load('organizer');
        }
        return $this->sendResponse($user, __('messages.retrieved'));
    }

    public function updateProfile(\App\Http\Requests\Auth\UpdateProfileRequest $request)
    {
        $user = $request->user();

        if ($request->has('name')) {
            $user->name = $request->name;
        }
        if ($request->has('phone')) {
            $user->phone = $request->phone;
        }

        $user->save();

        if ($user->role === 'organizer') {
            $user->load('organizer');
        }

        return $this->sendResponse($user, __('messages.updated'));
    }

    public function changePassword(Request $request)
    {
        $request->validate([
            'confirmation_token' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = $request->user();

        if (!$this->securityService->validateConfirmationToken($user, $request->confirmation_token)) {
            return $this->sendError('Invalid or expired confirmation token.', [], 403);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        $this->securityService->logActivity($request, 'password_changed', $user);
        $this->securityService->createAlert(
            $user,
            'password_changed',
            'high',
            'Password Changed',
            'Your account password was just changed.',
            $request
        );

        $user->notify(new \App\Notifications\PasswordChangedNotification());
        $user->notify(new \App\Notifications\SensitiveActionConfirmedNotification('Changed Password'));

        return $this->sendResponse(null, 'Password successfully changed.');
    }

    public function changeEmail(Request $request)
    {
        $request->validate([
            'confirmation_token' => 'required|string',
            'email' => 'required|email|unique:users,email',
        ]);

        $user = $request->user();

        if (!$this->securityService->validateConfirmationToken($user, $request->confirmation_token)) {
            return $this->sendError('Invalid or expired confirmation token.', [], 403);
        }

        $user->email = $request->email;
        $user->save();

        $this->securityService->logActivity($request, 'email_changed', $user);
        $this->securityService->createAlert(
            $user,
            'email_changed',
            'high',
            'Email Changed',
            'Your account email address was just changed to ' . $request->email . '.',
            $request
        );

        $user->notify(new \App\Notifications\SensitiveActionConfirmedNotification('Changed Email Address'));

        return $this->sendResponse($user, 'Email successfully changed.');
    }

    public function logout(Request $request)
    {
        $user = $request->user();
        $tokenId = $user->currentAccessToken()->id;
        
        $user->currentAccessToken()->delete();

        // Find the associated session and mark it as revoked/deleted
        $session = \App\Models\UserSession::where('token_id', $tokenId)->first();
        if ($session) {
            $session->delete(); // or ->update(['revoked_at' => now()]) based on preferences, let's delete for simplicity
        }

        $this->securityService->logActivity($request, 'logout', $user);

        return $this->sendResponse([], __('messages.login_success')); // Or 'logged_out' if we had one, but this is fine for now or I can just use 'success'
    }
}

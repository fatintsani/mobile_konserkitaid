<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends BaseController
{
    public function register(\App\Http\Requests\Auth\RegisterRequest $request)
    {
        $input = $request->validated();
        $input['password'] = Hash::make($input['password']);
        $input['role'] = $input['role'] ?? 'customer';
        
        $user = User::create($input);
        
        if ($input['role'] === 'organizer') {
            $user->organizer()->create([
                'company_name' => $user->name,
            ]);
        }
        
        $success['token'] =  $user->createToken('KonserKitaApp')->plainTextToken;
        $success['user'] =  $user;

        return $this->sendResponse($success, 'User register successfully.');
    }

    public function login(\App\Http\Requests\Auth\LoginRequest $request)
    {

        if(Auth::attempt(['email' => $request->email, 'password' => $request->password])){ 
            $user = Auth::user(); 
            $success['token'] =  $user->createToken('KonserKitaApp')->plainTextToken; 
            $success['user'] =  $user;
            
            if ($user->role === 'organizer') {
                $user->load('organizer');
                $success['user'] = $user;
            }

            return $this->sendResponse($success, 'User login successfully.');
        } 
        else{ 
            return $this->sendError('Unauthorised.', ['error'=>'Unauthorised'], 401);
        } 
    }

    public function profile(Request $request)
    {
        $user = $request->user();
        if ($user->role === 'organizer') {
            $user->load('organizer');
        }
        return $this->sendResponse($user, 'Profile retrieved successfully.');
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

        return $this->sendResponse($user, 'Profile updated successfully.');
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return $this->sendResponse([], 'User logged out successfully.');
    }
}

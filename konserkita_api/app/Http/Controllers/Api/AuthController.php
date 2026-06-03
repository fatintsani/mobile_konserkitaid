<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends BaseController
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6|confirmed',
            'role' => 'nullable|in:customer,organizer',
        ]);

        if($validator->fails()){
            return $this->sendError('Validation Error.', $validator->errors(), 422);       
        }

        $input = $request->all();
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

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if($validator->fails()){
            return $this->sendError('Validation Error.', $validator->errors(), 422);       
        }

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

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:20',
        ]);

        if($validator->fails()){
            return $this->sendError('Validation Error.', $validator->errors(), 422);       
        }

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

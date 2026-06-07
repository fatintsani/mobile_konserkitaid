<?php

namespace App\Http\Controllers\Api;

use App\Models\DeviceToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DeviceTokenController extends BaseController
{
    public function store(Request $request)
    {
        $request->validate([
            'token' => 'required|string',
            'platform' => 'nullable|string',
            'device_name' => 'nullable|string',
        ]);

        $user = Auth::user();

        // Use updateOrCreate to avoid duplicates
        $deviceToken = DeviceToken::updateOrCreate(
            ['token' => $request->token],
            [
                'user_id' => $user->id,
                'platform' => $request->platform,
                'device_name' => $request->device_name,
                'last_used_at' => now(),
            ]
        );

        return $this->sendResponse($deviceToken, 'Device token registered successfully.');
    }

    public function destroy(Request $request)
    {
        $request->validate([
            'token' => 'required|string',
        ]);

        DeviceToken::where('token', $request->token)
            ->where('user_id', Auth::id())
            ->delete();

        return $this->sendResponse([], 'Device token removed successfully.');
    }
}

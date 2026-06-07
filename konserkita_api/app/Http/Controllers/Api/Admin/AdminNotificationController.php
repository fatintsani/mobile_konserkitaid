<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use Illuminate\Http\Request;
use App\Services\PushNotificationService;

class AdminNotificationController extends BaseController
{
    protected $pushService;

    public function __construct(PushNotificationService $pushService)
    {
        $this->pushService = $pushService;
    }

    public function broadcast(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'target' => 'required|string|in:all,customers,organizers,admins',
            'event_id' => 'nullable|integer'
        ]);

        $data = [
            'type' => 'broadcast',
        ];

        if ($request->has('event_id')) {
            $data['event_id'] = (string) $request->event_id;
        }

        if ($request->target === 'all') {
            $this->pushService->sendToAll($request->title, $request->message, $data);
        } else {
            // Map target to role: customers -> customer, organizers -> organizer, admins -> admin
            $roleMap = [
                'customers' => 'customer',
                'organizers' => 'organizer',
                'admins' => 'admin',
            ];
            $role = $roleMap[$request->target];
            $this->pushService->sendToRole($role, $request->title, $request->message, $data);
        }

        return $this->sendResponse([], 'Broadcast notification sent successfully.');
    }
}

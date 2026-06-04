<?php

namespace App\Http\Controllers\Api;

use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends BaseController
{
    public function index(Request $request)
    {
        $notifications = Notification::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();
            
        return $this->sendResponse($notifications, 'Notifications retrieved successfully.');
    }

    public function markAsRead(Request $request, $id)
    {
        $notification = Notification::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (is_null($notification)) {
            return $this->sendError('Notification not found.');
        }

        $notification->is_read = true;
        $notification->save();

        return $this->sendResponse($notification, 'Notification marked as read.');
    }

    public function markAllAsRead(Request $request)
    {
        Notification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return $this->sendResponse([], 'All notifications marked as read.');
    }

    public function destroy(Request $request, $id)
    {
        $notification = Notification::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (is_null($notification)) {
            return $this->sendError('Notification not found.');
        }

        $notification->delete();

        return $this->sendResponse([], 'Notification deleted successfully.');
    }
}

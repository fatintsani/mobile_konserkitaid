<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\SecurityAlert;

class SecurityMonitoringController extends Controller
{
    public function index(Request $request)
    {
        $alerts = SecurityAlert::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->paginate($request->get('per_page', 15));

        $unreadCount = SecurityAlert::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->count();

        return response()->json([
            'data' => $alerts->items(),
            'current_page' => $alerts->currentPage(),
            'last_page' => $alerts->lastPage(),
            'total' => $alerts->total(),
            'unread_count' => $unreadCount,
        ]);
    }

    public function markAsRead(Request $request, $id)
    {
        $alert = SecurityAlert::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $alert->update(['is_read' => true]);

        return response()->json(['message' => 'Alert marked as read']);
    }

    public function markAllAsRead(Request $request)
    {
        SecurityAlert::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json(['message' => 'All alerts marked as read']);
    }
}

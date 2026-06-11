<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\ApiAbuseLog;

class ApiAbuseLogController extends Controller
{
    public function index(Request $request)
    {
        $query = ApiAbuseLog::query();

        if ($request->filled('ip_address')) {
            $query->where('ip_address', $request->ip_address);
        }

        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->filled('limiter')) {
            $query->where('limiter', $request->limiter);
        }

        if ($request->filled('endpoint')) {
            $query->where('endpoint', 'like', '%' . $request->endpoint . '%');
        }

        if ($request->filled('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $logs = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $logs
        ]);
    }
}

<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\AdminAuditLog;
use Illuminate\Http\Request;

class AdminAuditLogController extends BaseController
{
    /**
     * Get paginated admin audit logs.
     * Only accessible to super_admin or admin.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $query = AdminAuditLog::with('admin:id,name,email,role')
            ->orderBy('created_at', 'desc');

        // Normal admins might only see their own logs, but for transparency we can let them see all, 
        // or restrict based on requirements. The prompt says "Admin bisa melihat audit log. Super Admin bisa melihat semua dan filter lengkap."
        // We'll allow admins to see logs, but maybe only certain modules.
        // For now, let's implement the filter logic.
        
        if ($user->role !== 'super_admin') {
            // Depending on strictness, we might limit this. Let's let them see all for now but they can't filter everything?
            // "Super Admin bisa melihat semua dan filter lengkap."
            // So if admin, maybe restrict `admin_id` to themselves?
            // Let's restrict admin to only see their own logs, while super_admin sees all.
            $query->where('admin_id', $user->id);
        } else {
            if ($request->has('admin_id')) {
                $query->where('admin_id', $request->admin_id);
            }
        }

        if ($request->has('action')) {
            $query->where('action', $request->input('action'));
        }

        if ($request->has('module')) {
            $query->where('module', $request->input('module'));
        }

        if ($request->has('target_type')) {
            $query->where('target_type', 'like', '%' . $request->input('target_type') . '%');
        }

        if ($request->has('date_from')) {
            $query->whereDate('created_at', '>=', $request->input('date_from'));
        }

        if ($request->has('date_to')) {
            $query->whereDate('created_at', '<=', $request->input('date_to'));
        }

        $logs = $query->paginate(20);

        return $this->sendResponse($logs, 'Audit logs retrieved successfully.');
    }

    /**
     * Get a specific audit log detail.
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();
        
        $query = AdminAuditLog::with('admin:id,name,email,role');
        
        if ($user->role !== 'super_admin') {
            $query->where('admin_id', $user->id);
        }

        $log = $query->find($id);

        if (!$log) {
            return $this->sendError('Audit log not found or unauthorized.', [], 404);
        }

        return $this->sendResponse($log, 'Audit log retrieved successfully.');
    }
}

<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\SecurityAlert;
use App\Models\AccountLock;
use App\Services\AdminAuditService;

class AdminSecurityController extends Controller
{
    protected $auditService;

    public function __construct(AdminAuditService $auditService)
    {
        $this->auditService = $auditService;
    }
    public function alerts(Request $request)
    {
        $query = SecurityAlert::with('user:id,name,email');

        if ($request->has('severity')) {
            $query->where('severity', $request->severity);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('email')) {
            $query->where('email', 'like', '%' . $request->email . '%');
        }

        $alerts = $query->orderBy('created_at', 'desc')
            ->paginate($request->get('per_page', 20));

        return response()->json($alerts);
    }

    public function lockedAccounts(Request $request)
    {
        $query = AccountLock::with('user:id,name,email');

        if ($request->has('status')) {
            if ($request->status === 'locked') {
                $query->where(function($q) {
                    $q->where('locked_until', '>', now())
                      ->orWhereNull('locked_until');
                })->whereNull('unlocked_at');
            } elseif ($request->status === 'unlocked') {
                $query->whereNotNull('unlocked_at')
                      ->orWhere('locked_until', '<=', now());
            }
        }

        $locks = $query->orderBy('created_at', 'desc')
            ->paginate($request->get('per_page', 20));

        return response()->json($locks);
    }

    public function unlockAccount(Request $request, $id)
    {
        $lock = AccountLock::findOrFail($id);
        
        $oldValues = $lock->toArray();
        $lock->update([
            'unlocked_at' => now(),
            'locked_until' => now(), // expire it immediately
        ]);

        $this->auditService->log(
            auth()->user(),
            'security_account_unlocked',
            'security',
            $lock,
            $oldValues,
            $lock->toArray(),
            "Unlocked account for user ID: {$lock->user_id}"
        );

        return response()->json(['message' => 'Account unlocked successfully']);
    }
}

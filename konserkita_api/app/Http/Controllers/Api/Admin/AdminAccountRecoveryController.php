<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use Illuminate\Http\Request;
use App\Models\AccountRecoveryRequest;
use App\Models\User;
use App\Services\SecurityService;
use App\Services\AdminAuditService;
use App\Notifications\TwoFactorResetDecisionNotification;

class AdminAccountRecoveryController extends BaseController
{
    protected $securityService;
    protected $auditService;

    public function __construct(SecurityService $securityService, AdminAuditService $auditService)
    {
        $this->securityService = $securityService;
        $this->auditService = $auditService;
    }

    public function index(Request $request)
    {
        $query = AccountRecoveryRequest::with('user:id,name,email');

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        $requests = $query->orderBy('created_at', 'desc')->paginate(20);

        return $this->sendResponse($requests, 'Recovery requests retrieved.');
    }

    public function approve(Request $request, $id)
    {
        $recoveryRequest = AccountRecoveryRequest::findOrFail($id);

        if ($recoveryRequest->type !== AccountRecoveryRequest::TYPE_TWO_FACTOR_RESET) {
            return $this->sendError('Only Two-Factor Reset requests can be approved.', [], 400);
        }

        if ($recoveryRequest->status !== AccountRecoveryRequest::STATUS_PENDING) {
            return $this->sendError('Request is not in pending status.', [], 400);
        }

        $user = $recoveryRequest->user;
        if (!$user) {
            return $this->sendError('User not found.', [], 404);
        }

        // Disable 2FA
        $user->two_factor_enabled = false;
        $user->two_factor_secret = null;
        $user->two_factor_confirmed_at = null;
        $user->save();

        $user->twoFactorRecoveryCodes()->delete();

        // Revoke all sessions
        $user->tokens()->delete();
        $user->sessions()->update(['revoked_at' => now()]);

        // Mark request as approved
        $oldValues = $recoveryRequest->toArray();
        $recoveryRequest->update([
            'status' => AccountRecoveryRequest::STATUS_APPROVED,
            'completed_at' => now(),
            'admin_note' => $request->admin_note,
        ]);

        $this->auditService->log(
            auth()->user(),
            'account_recovery_approved',
            'account_recoveries',
            $recoveryRequest,
            $oldValues,
            $recoveryRequest->toArray(),
            "Approved two-factor reset for user: {$user->email}"
        );

        $this->securityService->logActivity($request, 'two_factor_disabled_by_admin', $user);
        $this->securityService->createAlert(
            $user,
            'two_factor_disabled',
            'critical',
            'Two-Factor Authentication Disabled',
            'Your Two-Factor Authentication was disabled by an administrator following your recovery request.',
            $request
        );

        $user->notify(new TwoFactorResetDecisionNotification('approved', $request->admin_note));

        return $this->sendResponse($recoveryRequest, 'Two-Factor Reset request approved.');
    }

    public function reject(Request $request, $id)
    {
        $request->validate([
            'admin_note' => 'required|string',
        ]);

        $recoveryRequest = AccountRecoveryRequest::findOrFail($id);

        if ($recoveryRequest->type !== AccountRecoveryRequest::TYPE_TWO_FACTOR_RESET) {
            return $this->sendError('Only Two-Factor Reset requests can be rejected here.', [], 400);
        }

        if ($recoveryRequest->status !== AccountRecoveryRequest::STATUS_PENDING) {
            return $this->sendError('Request is not in pending status.', [], 400);
        }

        // Mark request as rejected
        $oldValues = $recoveryRequest->toArray();
        $recoveryRequest->update([
            'status' => AccountRecoveryRequest::STATUS_REJECTED,
            'completed_at' => now(),
            'admin_note' => $request->admin_note,
        ]);

        $this->auditService->log(
            auth()->user(),
            'account_recovery_rejected',
            'account_recoveries',
            $recoveryRequest,
            $oldValues,
            $recoveryRequest->toArray(),
            "Rejected two-factor reset request #{$recoveryRequest->id}"
        );

        $user = $recoveryRequest->user;
        if ($user) {
            $user->notify(new TwoFactorResetDecisionNotification('rejected', $request->admin_note));
        }

        return $this->sendResponse($recoveryRequest, 'Two-Factor Reset request rejected.');
    }
}

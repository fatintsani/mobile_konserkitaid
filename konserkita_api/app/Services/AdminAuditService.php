<?php

namespace App\Services;

use App\Models\AdminAuditLog;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Request;

class AdminAuditService
{
    /**
     * Fields that should be masked in audit logs.
     */
    protected array $sensitiveFields = [
        'password',
        'password_confirmation',
        'token',
        'secret',
        'recovery_code',
        'two_factor_secret',
        'two_factor_recovery_codes',
        'snap_token',
        'firebase_token',
        'confirmation_token',
        'remember_token',
        'client_secret',
    ];

    /**
     * Mask sensitive data in arrays recursively.
     */
    protected function maskSensitiveData(?array $data): ?array
    {
        if (is_null($data)) {
            return null;
        }

        foreach ($data as $key => $value) {
            if (is_array($value)) {
                $data[$key] = $this->maskSensitiveData($value);
            } elseif (in_array(strtolower($key), $this->sensitiveFields)) {
                $data[$key] = '********';
            }
        }

        return $data;
    }

    /**
     * Log an admin action.
     *
     * @param \App\Models\User $admin The admin performing the action
     * @param string $action The action performed (e.g., 'event_approved')
     * @param string $module The module affected (e.g., 'events')
     * @param \Illuminate\Database\Eloquent\Model|null $target The target model
     * @param array|null $oldValues Old attribute values
     * @param array|null $newValues New attribute values
     * @param string|null $description Optional description
     * @return \App\Models\AdminAuditLog|null
     */
    public function log(
        $admin,
        string $action,
        string $module,
        ?Model $target = null,
        ?array $oldValues = null,
        ?array $newValues = null,
        ?string $description = null
    ): ?AdminAuditLog {
        try {
            $maskedOld = $this->maskSensitiveData($oldValues);
            $maskedNew = $this->maskSensitiveData($newValues);

            return AdminAuditLog::create([
                'admin_id' => $admin->id,
                'action' => $action,
                'module' => $module,
                'target_type' => $target ? get_class($target) : null,
                'target_id' => $target ? $target->getKey() : null,
                'description' => $description,
                'old_values' => $maskedOld,
                'new_values' => $maskedNew,
                'ip_address' => Request::ip(),
                'user_agent' => Request::userAgent(),
            ]);
        } catch (\Exception $e) {
            // We shouldn't break the main flow just because logging fails.
            \Log::error('Failed to create admin audit log: ' . $e->getMessage());
            return null;
        }
    }
}

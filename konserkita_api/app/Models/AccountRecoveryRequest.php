<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AccountRecoveryRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'email',
        'type',
        'status',
        'token_hash',
        'expires_at',
        'ip_address',
        'user_agent',
        'admin_note',
        'completed_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    // Types
    public const TYPE_PASSWORD_RESET = 'password_reset';
    public const TYPE_ACCOUNT_RECOVERY = 'account_recovery';
    public const TYPE_EMAIL_CHANGE = 'email_change';
    public const TYPE_TWO_FACTOR_RESET = 'two_factor_reset';

    // Statuses
    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';
    public const STATUS_EXPIRED = 'expired';
    public const STATUS_COMPLETED = 'completed';

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

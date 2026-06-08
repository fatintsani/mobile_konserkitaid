<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AdminAuditLog extends Model
{
    use HasFactory;

    public $timestamps = false; // Only created_at is used, but we handle it manually or let DB handle it. Actually we can use `const UPDATED_AT = null;` to keep created_at auto-managed.
    const UPDATED_AT = null;

    protected $fillable = [
        'admin_id',
        'action',
        'module',
        'target_type',
        'target_id',
        'description',
        'old_values',
        'new_values',
        'ip_address',
        'user_agent',
        'created_at'
    ];

    protected $casts = [
        'old_values' => 'array',
        'new_values' => 'array',
        'created_at' => 'datetime',
    ];

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function target()
    {
        return $this->morphTo();
    }
}

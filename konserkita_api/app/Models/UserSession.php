<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'token_id',
        'device_name',
        'platform',
        'browser',
        'ip_address',
        'user_agent',
        'last_active_at',
        'revoked_at',
    ];

    protected $casts = [
        'last_active_at' => 'datetime',
        'revoked_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

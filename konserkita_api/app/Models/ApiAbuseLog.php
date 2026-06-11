<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ApiAbuseLog extends Model
{
    const UPDATED_AT = null;

    protected $fillable = [
        'user_id',
        'ip_address',
        'endpoint',
        'method',
        'limiter',
        'request_count',
        'user_agent',
        'metadata',
    ];

    protected $casts = [
        'metadata' => 'array',
    ];
}

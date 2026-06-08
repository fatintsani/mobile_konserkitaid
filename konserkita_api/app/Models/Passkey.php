<?php

namespace App\Models;

use LaravelWebauthn\Models\WebauthnKey;

class Passkey extends WebauthnKey
{
    protected $table = 'passkeys';

    protected $casts = [
        'transports' => 'array',
        'trustPath' => 'array',
        'last_used_at' => 'datetime',
    ];
}

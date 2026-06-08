<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AccountLock extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'email',
        'reason',
        'locked_until',
        'unlocked_at',
    ];

    protected $casts = [
        'locked_until' => 'datetime',
        'unlocked_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

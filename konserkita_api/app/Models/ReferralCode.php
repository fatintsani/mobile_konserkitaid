<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ReferralCode extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'code',
        'type',
        'status',
        'commission_type',
        'commission_value',
        'max_reward',
        'usage_limit',
        'used_count',
        'expired_at',
    ];

    protected $casts = [
        'expired_at' => 'datetime',
        'commission_value' => 'decimal:2',
        'max_reward' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function clicks()
    {
        return $this->hasMany(ReferralClick::class);
    }

    public function conversions()
    {
        return $this->hasMany(ReferralConversion::class);
    }
}

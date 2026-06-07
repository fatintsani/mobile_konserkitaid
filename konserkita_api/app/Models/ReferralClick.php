<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ReferralClick extends Model
{
    use HasFactory;

    protected $fillable = [
        'referral_code_id',
        'ip_address',
        'user_agent',
        'clicked_at',
    ];

    public $timestamps = false;

    protected $casts = [
        'clicked_at' => 'datetime',
    ];

    public function referralCode()
    {
        return $this->belongsTo(ReferralCode::class);
    }
}

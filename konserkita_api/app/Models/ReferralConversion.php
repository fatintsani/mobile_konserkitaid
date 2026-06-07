<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ReferralConversion extends Model
{
    use HasFactory;

    protected $fillable = [
        'referral_code_id',
        'referred_user_id',
        'transaction_id',
        'commission_amount',
        'status',
    ];

    protected $casts = [
        'commission_amount' => 'decimal:2',
    ];

    public function referralCode()
    {
        return $this->belongsTo(ReferralCode::class);
    }

    public function referredUser()
    {
        return $this->belongsTo(User::class, 'referred_user_id');
    }

    public function transaction()
    {
        return $this->belongsTo(Transaction::class);
    }

    public function reward()
    {
        return $this->hasOne(ReferralReward::class);
    }
}

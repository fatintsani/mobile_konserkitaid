<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'transaction_id',
        'payment_type',
        'gateway_transaction_id',
        'gross_amount',
        'transaction_time',
        'transaction_status',
        'response_payload',
    ];

    protected $casts = [
        'response_payload' => 'array',
        'transaction_time' => 'datetime',
    ];

    public function transaction(): BelongsTo
    {
        return $this->belongsTo(Transaction::class);
    }
}

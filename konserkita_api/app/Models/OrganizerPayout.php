<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrganizerPayout extends Model
{
    use HasFactory;

    protected $fillable = [
        'organizer_id',
        'event_id',
        'requested_by',
        'amount',
        'platform_fee',
        'net_amount',
        'bank_name',
        'bank_account_name',
        'bank_account_number',
        'status',
        'admin_note',
        'requested_at',
        'approved_at',
        'paid_at',
    ];

    protected $casts = [
        'requested_at' => 'datetime',
        'approved_at' => 'datetime',
        'paid_at' => 'datetime',
    ];

    public function organizer(): BelongsTo
    {
        return $this->belongsTo(Organizer::class);
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by');
    }
}

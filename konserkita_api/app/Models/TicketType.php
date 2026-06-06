<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TicketType extends Model
{
    use HasFactory;

    protected $fillable = [
        'event_id',
        'name',
        'description',
        'price',
        'stock',
        'max_buy_per_transaction',
        'requires_seat',
    ];

    protected $appends = ['quota', 'status'];

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function getQuotaAttribute()
    {
        return $this->stock;
    }

    public function getStatusAttribute()
    {
        return $this->stock > 0 ? 'available' : 'sold_out';
    }
}

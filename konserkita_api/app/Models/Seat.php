<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Seat extends Model
{
    use HasFactory;

    protected $fillable = [
        'venue_section_id',
        'row_label',
        'seat_number',
        'seat_code',
        'status',
    ];

    public function section(): BelongsTo
    {
        return $this->belongsTo(VenueSection::class, 'venue_section_id');
    }
}

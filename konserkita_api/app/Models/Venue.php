<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Venue extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'city',
        'address',
        'capacity',
        'status',
    ];

    public function sections(): HasMany
    {
        return $this->hasMany(VenueSection::class);
    }

    public function seatMaps(): HasMany
    {
        return $this->hasMany(EventSeatMap::class);
    }
}

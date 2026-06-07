<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserEventInteraction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'event_id',
        'interaction_type',
        'weight',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function event()
    {
        return $this->belongsTo(Event::class);
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\Pivot;

class OrganizerFollower extends Pivot
{
    protected $table = 'organizer_followers';

    protected $fillable = [
        'organizer_id',
        'user_id',
    ];
}

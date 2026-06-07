<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserPreference extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'preferred_categories',
        'preferred_locations',
        'min_price',
        'max_price',
    ];

    protected $casts = [
        'preferred_categories' => 'array',
        'preferred_locations' => 'array',
        'min_price' => 'decimal:2',
        'max_price' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

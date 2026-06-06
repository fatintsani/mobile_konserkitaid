<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Organizer extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'company_name',
        'description',
        'logo',
        'website',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected function logo(): \Illuminate\Database\Eloquent\Casts\Attribute
    {
        return \Illuminate\Database\Eloquent\Casts\Attribute::make(
            get: fn ($value) => $value ? $value : url('default_img.png'),
        );
    }
}

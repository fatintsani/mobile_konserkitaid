<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class EventCategory extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'icon',
        'slug',
        'description',
        'status',
    ];

    public function events(): HasMany
    {
        return $this->hasMany(Event::class, 'category_id');
    }

    protected function icon(): \Illuminate\Database\Eloquent\Casts\Attribute
    {
        return \Illuminate\Database\Eloquent\Casts\Attribute::make(
            get: fn ($value) => $value ? $value : url('default_img.png'),
        );
    }
}

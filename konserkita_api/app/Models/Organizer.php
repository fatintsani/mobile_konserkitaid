<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Organizer extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'company_name',
        'description',
        'logo',
        'website',
        'slug',
        'public_name',
        'cover_image',
        'instagram_url',
        'description_en',
        'rating_average',
        'total_reviews',
        'total_events',
        'total_followers',
        'verification_badge',
        'status',
    ];

    protected $casts = [
        'verification_badge' => 'boolean',
        'rating_average' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function events(): HasMany
    {
        return $this->hasMany(Event::class);
    }

    public function followers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'organizer_followers', 'organizer_id', 'user_id')->withTimestamps();
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(OrganizerReview::class);
    }

    protected function logo(): \Illuminate\Database\Eloquent\Casts\Attribute
    {
        return \Illuminate\Database\Eloquent\Casts\Attribute::make(
            get: fn ($value) => $value ? $value : url('default_img.png'),
        );
    }

    protected function coverImage(): \Illuminate\Database\Eloquent\Casts\Attribute
    {
        return \Illuminate\Database\Eloquent\Casts\Attribute::make(
            get: fn ($value) => $value ? $value : url('default_img.png'),
        );
    }
}

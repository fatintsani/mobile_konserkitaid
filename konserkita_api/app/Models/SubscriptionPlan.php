<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SubscriptionPlan extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'price',
        'billing_cycle',
        'max_events',
        'max_tickets_per_event',
        'max_admin_users',
        'platform_fee_percentage',
        'features',
        'status',
    ];

    protected $casts = [
        'features' => 'array',
        'price' => 'decimal:2',
        'platform_fee_percentage' => 'decimal:2',
    ];

    public function subscriptions(): HasMany
    {
        return $this->hasMany(OrganizerSubscription::class);
    }
}

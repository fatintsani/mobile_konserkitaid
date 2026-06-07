<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\SubscriptionPlan;

class SubscriptionPlanSeeder extends Seeder
{
    public function run(): void
    {
        SubscriptionPlan::create([
            'name' => 'Trial',
            'slug' => 'trial',
            'price' => 0,
            'billing_cycle' => 'monthly',
            'max_events' => 1,
            'max_tickets_per_event' => 50,
            'max_admin_users' => 1,
            'platform_fee_percentage' => 15.00,
            'features' => [
                'event_creation' => true,
                'ticket_sales' => true,
                'analytics' => false,
                'custom_domain' => false,
            ],
            'status' => 'active',
        ]);

        SubscriptionPlan::create([
            'name' => 'Pro',
            'slug' => 'pro',
            'price' => 299000,
            'billing_cycle' => 'monthly',
            'max_events' => 10,
            'max_tickets_per_event' => 1000,
            'max_admin_users' => 3,
            'platform_fee_percentage' => 7.50,
            'features' => [
                'event_creation' => true,
                'ticket_sales' => true,
                'analytics' => true,
                'custom_domain' => false,
            ],
            'status' => 'active',
        ]);

        SubscriptionPlan::create([
            'name' => 'Enterprise',
            'slug' => 'enterprise',
            'price' => 999000,
            'billing_cycle' => 'monthly',
            'max_events' => 9999,
            'max_tickets_per_event' => 999999,
            'max_admin_users' => 10,
            'platform_fee_percentage' => 5.00,
            'features' => [
                'event_creation' => true,
                'ticket_sales' => true,
                'analytics' => true,
                'custom_domain' => true,
            ],
            'status' => 'active',
        ]);
    }
}

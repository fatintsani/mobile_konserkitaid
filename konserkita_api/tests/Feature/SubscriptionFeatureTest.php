<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use App\Models\Organizer;
use App\Models\SubscriptionPlan;
use Laravel\Sanctum\Sanctum;

class SubscriptionFeatureTest extends TestCase
{
    use RefreshDatabase;

    public function setUp(): void
    {
        parent::setUp();
        
        SubscriptionPlan::create([
            'name' => 'Trial',
            'slug' => 'trial',
            'price' => 0,
            'billing_cycle' => 'monthly',
            'max_events' => 1,
            'max_tickets_per_event' => 50,
            'max_admin_users' => 1,
            'platform_fee_percentage' => 15.00,
            'features' => ['event_creation' => true],
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
            'features' => ['event_creation' => true],
            'status' => 'active',
        ]);

        \App\Models\EventCategory::create([
            'name' => 'Music',
            'name_en' => 'Music',
            'icon' => 'music',
            'color' => '#000000',
        ]);
    }

    public function test_new_organizer_gets_trial_subscription()
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Test Organizer',
            'email' => 'organizer@test.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'organizer',
        ]);

        $response->assertStatus(200);

        $user = User::where('email', 'organizer@test.com')->first();
        $this->assertNotNull($user->organizer);
        
        $subscription = $user->organizer->subscription;
        $this->assertNotNull($subscription);
        $this->assertEquals('trialing', $subscription->status);
        $this->assertEquals('trial', $subscription->plan->slug);
    }

    public function test_organizer_can_fetch_subscription_details()
    {
        $user = User::factory()->create(['role' => 'organizer']);
        $organizer = Organizer::factory()->create(['user_id' => $user->id]);
        
        $plan = SubscriptionPlan::where('slug', 'trial')->first();
        $organizer->subscription()->create([
            'subscription_plan_id' => $plan->id,
            'status' => 'trialing',
            'starts_at' => now(),
            'trial_ends_at' => now()->addDays(14),
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/organizer/subscription');

        $response->assertStatus(200)
                 ->assertJsonPath('data.subscription.status', 'trialing')
                 ->assertJsonPath('data.subscription.plan.slug', 'trial');
    }

    public function test_organizer_cannot_create_event_if_limit_reached()
    {
        $user = User::factory()->create(['role' => 'organizer']);
        $organizer = Organizer::factory()->create(['user_id' => $user->id]);
        
        $plan = SubscriptionPlan::where('slug', 'trial')->first();
        $organizer->subscription()->create([
            'subscription_plan_id' => $plan->id,
            'status' => 'trialing',
            'starts_at' => now(),
            'trial_ends_at' => now()->addDays(14),
        ]);

        // Max events for trial is 1. We mock that they already created 1.
        $organizer->limits()->create([
            'current_month_events' => 1,
            'current_month_tickets_sold' => 0,
            'reset_at' => now(),
        ]);

        Sanctum::actingAs($user);

        $response = $this->postJson('/api/organizer/events', [
            'title' => 'New Event',
            'title_en' => 'New Event',
            'description' => 'Test event',
            'description_id' => 'Test event ID',
            'description_en' => 'Test event EN',
            'date' => now()->addDays(5)->format('Y-m-d'),
            'time' => '19:00',
            'location' => 'Online',
            'venue_id' => 1,
            'category_id' => 1,
        ]);

        $response->assertStatus(403)
                 ->assertJsonPath('message', 'You have reached your maximum event limit for your current subscription plan.');
    }
}

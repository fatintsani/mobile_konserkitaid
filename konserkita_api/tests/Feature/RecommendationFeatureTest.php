<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use App\Models\Event;
use App\Models\EventCategory;
use App\Models\Organizer;
use App\Models\UserEventInteraction;
use Illuminate\Support\Facades\Artisan;

class RecommendationFeatureTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_record_interaction()
    {
        $user = User::factory()->create();
        $organizer = Organizer::create([
            'user_id' => $user->id,
            'company_name' => 'Test Company',
            'legal_name' => 'PT Test',
            'description' => 'Test',
            'status' => 'approved'
        ]);
        $category = EventCategory::create(['name' => 'Test', 'icon' => 'test']);
        $event = Event::create([
            'organizer_id' => $organizer->id,
            'category_id' => $category->id,
            'title' => 'Test Event',
            'slug' => 'test-event-1',
            'description' => 'Test Event',
            'date' => now()->addDays(2)->format('Y-m-d'),
            'time' => '19:00:00',
            'location' => 'Jakarta',
            'status' => 'published',
            'is_numbered_seating' => false,
        ]);

        $response = $this->actingAs($user)->postJson('/api/interactions', [
            'event_id' => $event->id,
            'interaction_type' => 'view',
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('user_event_interactions', [
            'user_id' => $user->id,
            'event_id' => $event->id,
            'interaction_type' => 'view',
        ]);
    }

    public function test_recommendation_generation_excludes_past_events()
    {
        $user = User::factory()->create();
        $organizer = Organizer::create([
            'user_id' => $user->id,
            'company_name' => 'Test Company',
            'legal_name' => 'PT Test',
            'description' => 'Test',
            'status' => 'approved'
        ]);
        $category = EventCategory::create(['name' => 'Test', 'icon' => 'test']);
        
        $pastEvent = Event::create([
            'organizer_id' => $organizer->id,
            'category_id' => $category->id,
            'title' => 'Past Event',
            'slug' => 'past-event-1',
            'description' => 'Past Event',
            'date' => now()->subDays(2)->format('Y-m-d'),
            'time' => '19:00:00',
            'location' => 'Jakarta',
            'status' => 'published',
            'is_numbered_seating' => false,
        ]);

        $futureEvent = Event::create([
            'organizer_id' => $organizer->id,
            'category_id' => $category->id,
            'title' => 'Future Event',
            'slug' => 'future-event-1',
            'description' => 'Future Event',
            'date' => now()->addDays(2)->format('Y-m-d'),
            'time' => '19:00:00',
            'location' => 'Jakarta',
            'status' => 'published',
            'is_numbered_seating' => false,
        ]);

        // Run command
        Artisan::call('recommendations:generate');

        // Past event should not be recommended
        $this->assertDatabaseMissing('event_recommendations', [
            'user_id' => $user->id,
            'event_id' => $pastEvent->id,
        ]);

        // Future event should be recommended
        $this->assertDatabaseHas('event_recommendations', [
            'user_id' => $user->id,
            'event_id' => $futureEvent->id,
        ]);
    }
}

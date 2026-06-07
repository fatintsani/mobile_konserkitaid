<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use App\Models\Organizer;
use App\Models\Event;

class OrganizerMarketplaceFeatureTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_can_view_verified_organizers()
    {
        Organizer::factory()->create(['status' => 'verified', 'verification_badge' => true, 'slug' => 'org-1']);
        Organizer::factory()->create(['status' => 'pending', 'slug' => 'org-2']);

        $response = $this->getJson('/api/organizers');

        $response->assertStatus(200);
        $response->assertJsonCount(1, 'data.data');
        $response->assertJsonPath('data.data.0.slug', 'org-1');
    }

    public function test_user_can_follow_organizer()
    {
        $user = User::factory()->create();
        $organizer = Organizer::factory()->create(['status' => 'verified', 'slug' => 'org-1']);

        $response = $this->actingAs($user)->postJson('/api/organizers/' . $organizer->id . '/follow');

        $response->assertStatus(200);
        $this->assertDatabaseHas('organizer_followers', [
            'user_id' => $user->id,
            'organizer_id' => $organizer->id
        ]);
        
        $this->assertEquals(1, $organizer->fresh()->total_followers);
    }
}

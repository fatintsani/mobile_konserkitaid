<?php
namespace Tests\Feature;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Organizer;

class OrganizerRouteProtectionTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_cannot_access_organizer()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $response = $this->actingAs($user)->getJson('/api/organizer/dashboard');
        $response->assertStatus(403);
    }

    public function test_organizer_can_access()
    {
        $user = User::factory()->create(['role' => 'organizer']);
        Organizer::factory()->create(['user_id' => $user->id]);
        $response = $this->actingAs($user)->getJson('/api/organizer/dashboard');
        $response->assertStatus(200);
    }
}
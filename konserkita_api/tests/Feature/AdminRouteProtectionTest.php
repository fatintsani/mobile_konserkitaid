<?php
namespace Tests\Feature;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;

class AdminRouteProtectionTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_cannot_access_admin()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $response = $this->actingAs($user)->getJson('/api/admin/dashboard');
        $response->assertStatus(403);
    }

    public function test_admin_can_access()
    {
        $user = User::factory()->create(['role' => 'admin']);
        $response = $this->actingAs($user)->getJson('/api/admin/dashboard');
        $response->assertStatus(200);
    }
}
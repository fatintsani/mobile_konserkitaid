<?php
namespace Tests\Feature;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;

class TicketScanTest extends TestCase
{
    use RefreshDatabase;

    public function test_ticket_scan_requires_role()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $response = $this->actingAs($user)->postJson('/api/tickets/scan', ['ticket_code' => 'XYZ123']);
        $response->assertStatus(403);
    }
}
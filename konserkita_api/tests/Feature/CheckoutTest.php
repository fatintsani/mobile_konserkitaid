<?php
namespace Tests\Feature;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Event;
use App\Models\TicketType;

class CheckoutTest extends TestCase
{
    use RefreshDatabase;

    public function test_checkout_requires_auth()
    {
        $response = $this->postJson('/api/checkout', []);
        $response->assertStatus(401);
    }
}
<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use App\Models\ApiAbuseLog;

class ApiRateLimitTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_rate_limit_and_abuse_logging()
    {
        $email = 'test@example.com';
        
        // 5 requests allowed per minute for login
        for ($i = 0; $i < 5; $i++) {
            $response = $this->postJson('/api/login', [
                'email' => $email,
                'password' => 'password',
            ]);
            // Don't assert status as it might fail auth, just that it's not 429
            $response->assertStatus(401); // Unauthorized error since no DB user created for test
        }

        // 6th request should hit rate limit
        $response = $this->postJson('/api/login', [
            'email' => $email,
            'password' => 'password',
        ]);
        
        $response->assertStatus(429);

        // Check if log is created
        $this->assertDatabaseHas('api_abuse_logs', [
            'endpoint' => 'api/login',
            'limiter' => 'auth_login',
        ]);
    }

    public function test_public_search_rate_limit()
    {
        // 60 requests allowed per minute for public search
        for ($i = 0; $i < 60; $i++) {
            $response = $this->getJson('/api/events');
            $response->assertStatus(200);
        }

        // 61st request should hit rate limit
        $response = $this->getJson('/api/events');
        $response->assertStatus(429);

        // Check if log is created
        $this->assertDatabaseHas('api_abuse_logs', [
            'endpoint' => 'api/events',
            'limiter' => 'public_search',
        ]);
    }

    public function test_admin_can_view_abuse_logs()
    {
        $admin = User::factory()->create(['role' => 'admin']);

        ApiAbuseLog::create([
            'ip_address' => '127.0.0.1',
            'endpoint' => 'api/login',
            'method' => 'POST',
            'limiter' => 'auth_login'
        ]);

        $response = $this->actingAs($admin)->getJson('/api/admin/security/api-abuse-logs');

        $response->assertStatus(200)
                 ->assertJsonPath('data.total', 1);
    }
}

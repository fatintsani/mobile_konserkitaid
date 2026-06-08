<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use App\Models\UserSession;
use App\Models\LoginActivity;

class SessionManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_creates_session_and_activity()
    {
        $user = User::factory()->create([
            'password' => bcrypt('password123'),
        ]);

        $response = $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'password123',
        ], [
            'User-Agent' => 'TestBrowser/1.0',
        ]);

        $response->assertStatus(200);

        // Check if session was created
        $this->assertDatabaseHas('user_sessions', [
            'user_id' => $user->id,
            'browser' => 'Unknown', // 'TestBrowser' isn't explicitly checked in SecurityService getBrowser, so it's Unknown
        ]);

        // Check if activity was logged
        $this->assertDatabaseHas('login_activities', [
            'user_id' => $user->id,
            'email' => $user->email,
            'event_type' => 'login_success',
        ]);
    }

    public function test_failed_login_creates_activity()
    {
        $response = $this->postJson('/api/login', [
            'email' => 'wrong@example.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401);

        $this->assertDatabaseHas('login_activities', [
            'email' => 'wrong@example.com',
            'event_type' => 'login_failed',
        ]);
    }

    public function test_user_can_view_own_sessions()
    {
        $user = User::factory()->create();
        \Laravel\Sanctum\Sanctum::actingAs($user);

        // Create dummy sessions
        UserSession::create([
            'user_id' => $user->id,
            'device_name' => 'Test Device 1',
            'last_active_at' => now(),
        ]);
        UserSession::create([
            'user_id' => $user->id,
            'device_name' => 'Test Device 2',
            'last_active_at' => now(),
        ]);

        $response = $this->getJson('/api/security/sessions');
        $response->assertStatus(200);
        $response->assertJsonCount(2);
    }

    public function test_user_can_revoke_own_session()
    {
        $user = User::factory()->create();
        \Laravel\Sanctum\Sanctum::actingAs($user);

        $session = UserSession::create([
            'user_id' => $user->id,
            'device_name' => 'Device to revoke',
            'last_active_at' => now(),
        ]);

        $response = $this->deleteJson("/api/security/sessions/{$session->id}");
        $response->assertStatus(200);

        $this->assertDatabaseMissing('user_sessions', [
            'id' => $session->id,
        ]);

        $this->assertDatabaseHas('login_activities', [
            'user_id' => $user->id,
            'event_type' => 'session_revoked',
        ]);
    }

    public function test_user_can_revoke_other_sessions()
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token');
        $this->withHeaders(['Authorization' => 'Bearer ' . $token->plainTextToken]);

        // Current session
        UserSession::create([
            'user_id' => $user->id,
            'token_id' => $token->accessToken->id,
            'device_name' => 'Current Device',
            'last_active_at' => now(),
        ]);

        // Other session
        UserSession::create([
            'user_id' => $user->id,
            'token_id' => 999, // Fake token
            'device_name' => 'Other Device',
            'last_active_at' => now(),
        ]);

        $response = $this->deleteJson('/api/security/sessions/revoke-others');
        $response->assertStatus(200);

        $this->assertDatabaseHas('user_sessions', [
            'token_id' => $token->accessToken->id,
        ]);

        $this->assertDatabaseMissing('user_sessions', [
            'token_id' => 999,
        ]);
    }

    public function test_user_can_view_login_activities()
    {
        $user = User::factory()->create();
        \Laravel\Sanctum\Sanctum::actingAs($user);

        LoginActivity::create([
            'user_id' => $user->id,
            'event_type' => 'login_success',
        ]);

        $response = $this->getJson('/api/security/login-activities');
        $response->assertStatus(200);
        $response->assertJsonStructure([
            'data' => [
                '*' => [
                    'id', 'event_type', 'created_at'
                ]
            ],
            'current_page',
            'last_page'
        ]);
    }
}

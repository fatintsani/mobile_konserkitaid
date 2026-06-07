<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\User;
use App\Models\DeviceToken;
use Tests\TestCase;

class FcmPushNotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_device_token()
    {
        $user = User::factory()->create();
        $this->actingAs($user);

        $response = $this->postJson('/api/device-tokens', [
            'token' => 'dummy-fcm-token-123',
            'platform' => 'android',
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $user->id,
            'token' => 'dummy-fcm-token-123',
        ]);
    }

    public function test_user_can_unregister_device_token()
    {
        $user = User::factory()->create();
        $this->actingAs($user);

        DeviceToken::create([
            'user_id' => $user->id,
            'token' => 'token-to-delete',
        ]);

        $response = $this->deleteJson('/api/device-tokens', [
            'token' => 'token-to-delete',
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseMissing('device_tokens', [
            'token' => 'token-to-delete',
        ]);
    }

    public function test_admin_can_broadcast_notification()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->actingAs($admin);

        // We mock the push service or just let it handle empty tokens gracefully
        // The service has a try-catch for Firebase init, so it won't crash even if we don't have creds
        $response = $this->postJson('/api/admin/notifications/broadcast', [
            'title' => 'Test Broadcast',
            'message' => 'Hello everyone',
            'target' => 'all',
        ]);

        $response->assertStatus(200);
    }
}

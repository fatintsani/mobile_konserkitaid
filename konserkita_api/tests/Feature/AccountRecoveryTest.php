<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\AccountRecoveryRequest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Laravel\Sanctum\Sanctum;

class AccountRecoveryTest extends TestCase
{
    use RefreshDatabase;

    public function test_forgot_password_creates_recovery_request()
    {
        $user = User::factory()->create();

        $response = $this->postJson('/api/auth/forgot-password', [
            'email' => $user->email,
        ]);

        $response->dump();
        $response->assertStatus(200);

        $this->assertDatabaseHas('account_recovery_requests', [
            'user_id' => $user->id,
            'type' => AccountRecoveryRequest::TYPE_PASSWORD_RESET,
        ]);
    }

    public function test_reset_password_with_valid_token()
    {
        $user = User::factory()->create();
        $token = 'random-token-123';

        AccountRecoveryRequest::create([
            'user_id' => $user->id,
            'email' => $user->email,
            'type' => AccountRecoveryRequest::TYPE_PASSWORD_RESET,
            'status' => AccountRecoveryRequest::STATUS_PENDING,
            'token_hash' => hash('sha256', $token),
            'expires_at' => now()->addMinutes(15),
        ]);

        $response = $this->postJson('/api/auth/reset-password', [
            'email' => $user->email,
            'token' => $token,
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('account_recovery_requests', [
            'user_id' => $user->id,
            'status' => AccountRecoveryRequest::STATUS_COMPLETED,
        ]);
    }

    public function test_two_factor_reset_request()
    {
        $user = User::factory()->create(['two_factor_enabled' => true]);

        $response = $this->postJson('/api/account-recovery/two-factor-reset', [
            'email' => $user->email,
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('account_recovery_requests', [
            'user_id' => $user->id,
            'type' => AccountRecoveryRequest::TYPE_TWO_FACTOR_RESET,
            'status' => AccountRecoveryRequest::STATUS_PENDING,
        ]);
    }

    public function test_sensitive_action_confirmation()
    {
        $user = User::factory()->create(['password' => bcrypt('password')]);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/security/confirm-password', [
            'password' => 'password',
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure(['data' => ['confirmation_token']]);
    }

    public function test_admin_approve_two_factor_reset()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $user = User::factory()->create(['two_factor_enabled' => true]);
        $request = AccountRecoveryRequest::create([
            'user_id' => $user->id,
            'email' => $user->email,
            'type' => AccountRecoveryRequest::TYPE_TWO_FACTOR_RESET,
            'status' => AccountRecoveryRequest::STATUS_PENDING,
            'expires_at' => now()->addDays(7),
        ]);

        $response = $this->putJson('/api/admin/account-recovery/requests/' . $request->id . '/decision', [
            'status' => 'approved',
        ]);
        
        $response->dump();

        $response->assertStatus(200);

        $this->assertDatabaseHas('account_recovery_requests', [
            'id' => $request->id,
            'status' => AccountRecoveryRequest::STATUS_APPROVED,
        ]);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'two_factor_enabled' => 0,
        ]);
    }
}

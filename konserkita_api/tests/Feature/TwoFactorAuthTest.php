<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use PragmaRX\Google2FA\Google2FA;

class TwoFactorAuthTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // create a user
        $this->user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('password123'),
        ]);
    }

    public function test_user_can_setup_2fa()
    {
        $response = $this->actingAs($this->user)->postJson('/api/2fa/setup');

        $response->assertStatus(200)
                 ->assertJsonStructure(['secret', 'qr_code_svg']);

        $this->assertNotNull($this->user->fresh()->two_factor_secret);
    }

    public function test_user_can_confirm_2fa_with_valid_code()
    {
        $google2fa = app('pragmarx.google2fa');
        $secret = $google2fa->generateSecretKey();
        
        $this->user->update(['two_factor_secret' => $secret]);

        $validCode = $google2fa->getCurrentOtp($secret);

        $response = $this->actingAs($this->user)->postJson('/api/2fa/confirm', [
            'code' => $validCode
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure(['message', 'recovery_codes']);

        $this->assertTrue((bool)$this->user->fresh()->two_factor_enabled);
        $this->assertNotNull($this->user->fresh()->two_factor_confirmed_at);
        $this->assertCount(8, $this->user->twoFactorRecoveryCodes);
    }

    public function test_login_returns_requires_2fa_if_enabled()
    {
        $google2fa = app('pragmarx.google2fa');
        $this->user->update([
            'two_factor_enabled' => true,
            'two_factor_secret' => $google2fa->generateSecretKey()
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'test@example.com',
            'password' => 'password123'
        ]);

        $response->assertStatus(200)
                 ->assertJson([
                     'requires_2fa' => true
                 ])
                 ->assertJsonStructure(['temporary_token']);
    }

    public function test_user_can_pass_challenge_with_valid_code()
    {
        $google2fa = app('pragmarx.google2fa');
        $secret = $google2fa->generateSecretKey();

        $this->user->update([
            'two_factor_enabled' => true,
            'two_factor_secret' => $secret
        ]);

        // Get temporary token
        $loginResponse = $this->postJson('/api/login', [
            'email' => 'test@example.com',
            'password' => 'password123'
        ]);

        $tempToken = $loginResponse->json('temporary_token');
        $validCode = $google2fa->getCurrentOtp($secret);

        $response = $this->postJson('/api/2fa/challenge', [
            'temporary_token' => $tempToken,
            'code' => $validCode
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure(['token', 'user']);
    }

    public function test_user_can_pass_challenge_with_recovery_code()
    {
        $google2fa = app('pragmarx.google2fa');
        $this->user->update([
            'two_factor_enabled' => true,
            'two_factor_secret' => $google2fa->generateSecretKey()
        ]);

        $recoveryCode = '12345-67890';
        $this->user->twoFactorRecoveryCodes()->create([
            'code_hash' => Hash::make($recoveryCode)
        ]);

        $loginResponse = $this->postJson('/api/login', [
            'email' => 'test@example.com',
            'password' => 'password123'
        ]);

        $tempToken = $loginResponse->json('temporary_token');

        $response = $this->postJson('/api/2fa/challenge', [
            'temporary_token' => $tempToken,
            'recovery_code' => $recoveryCode
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure(['token', 'user']);

        $this->assertNotNull($this->user->twoFactorRecoveryCodes()->first()->used_at);
    }
}

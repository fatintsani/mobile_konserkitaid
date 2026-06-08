<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class WebauthnPasskeyTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_request_passkey_registration_options()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/passkeys/register/options');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'rp' => ['name', 'id'],
            'user' => ['id', 'name', 'displayName'],
            'challenge',
            'pubKeyCredParams',
        ]);
    }

    public function test_user_can_request_passkey_login_options()
    {
        $user = User::factory()->create();

        $response = $this->postJson('/api/passkeys/login/options', ['email' => $user->email]);

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'challenge',
            'allowCredentials',
        ]);
    }

    public function test_user_can_list_passkeys()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->getJson('/api/passkeys');

        $response->assertStatus(200);
    }
}

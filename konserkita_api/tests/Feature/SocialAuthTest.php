<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Socialite\Facades\Socialite;
use Tests\TestCase;
use Mockery;

class SocialAuthTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
    }

    public function test_google_login_create_user()
    {
        $abstractUser = Mockery::mock('Laravel\Socialite\Two\User');
        $abstractUser->shouldReceive('getId')->andReturn('google-12345');
        $abstractUser->shouldReceive('getName')->andReturn('Google User');
        $abstractUser->shouldReceive('getEmail')->andReturn('google@example.com');
        $abstractUser->shouldReceive('getAvatar')->andReturn('https://google.com/avatar.jpg');

        $provider = Mockery::mock('Laravel\Socialite\Contracts\Provider');
        $provider->shouldReceive('stateless')->andReturn($provider);
        $provider->shouldReceive('userFromToken')->with('valid-token')->andReturn($abstractUser);

        Socialite::shouldReceive('driver')->with('google')->andReturn($provider);

        $response = $this->postJson('/api/auth/google', [
            'access_token' => 'valid-token'
        ]);

        $response->assertStatus(200);
        $response->assertJsonStructure(['success', 'data' => ['user', 'token'], 'message']);

        $this->assertDatabaseHas('users', [
            'email' => 'google@example.com',
            'provider' => 'google',
            'provider_id' => 'google-12345',
        ]);
    }

    public function test_google_login_existing_user()
    {
        $user = User::factory()->create([
            'email' => 'existing@example.com',
            'provider' => null,
            'provider_id' => null,
        ]);

        $abstractUser = Mockery::mock('Laravel\Socialite\Two\User');
        $abstractUser->shouldReceive('getId')->andReturn('google-54321');
        $abstractUser->shouldReceive('getName')->andReturn('Existing User');
        $abstractUser->shouldReceive('getEmail')->andReturn('existing@example.com');
        $abstractUser->shouldReceive('getAvatar')->andReturn('https://google.com/avatar.jpg');

        $provider = Mockery::mock('Laravel\Socialite\Contracts\Provider');
        $provider->shouldReceive('stateless')->andReturn($provider);
        $provider->shouldReceive('userFromToken')->with('valid-token')->andReturn($abstractUser);

        Socialite::shouldReceive('driver')->with('google')->andReturn($provider);

        $response = $this->postJson('/api/auth/google', [
            'access_token' => 'valid-token'
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'email' => 'existing@example.com',
            'provider' => 'google',
            'provider_id' => 'google-54321',
        ]);
        
        $this->assertDatabaseCount('users', 1);
    }

    public function test_microsoft_login_create_user()
    {
        $abstractUser = Mockery::mock('Laravel\Socialite\Two\User');
        $abstractUser->shouldReceive('getId')->andReturn('microsoft-12345');
        $abstractUser->shouldReceive('getName')->andReturn('Microsoft User');
        $abstractUser->shouldReceive('getEmail')->andReturn('microsoft@example.com');
        $abstractUser->shouldReceive('getAvatar')->andReturn('https://microsoft.com/avatar.jpg');

        $provider = Mockery::mock('Laravel\Socialite\Contracts\Provider');
        $provider->shouldReceive('stateless')->andReturn($provider);
        $provider->shouldReceive('userFromToken')->with('valid-token')->andReturn($abstractUser);

        Socialite::shouldReceive('driver')->with('microsoft')->andReturn($provider);

        $response = $this->postJson('/api/auth/microsoft', [
            'access_token' => 'valid-token'
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'email' => 'microsoft@example.com',
            'provider' => 'microsoft',
            'provider_id' => 'microsoft-12345',
        ]);
    }
}

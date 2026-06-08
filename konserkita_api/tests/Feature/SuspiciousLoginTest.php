<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Foundation\Testing\WithoutMiddleware;
use Tests\TestCase;
use App\Models\User;
use App\Models\AccountLock;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;

class SuspiciousLoginTest extends TestCase
{
    use RefreshDatabase, WithoutMiddleware;

    protected function setUp(): void
    {
        parent::setUp();
        // Clear rate limiter cache
        RateLimiter::clear('login');
        
        $this->user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('password123'),
        ]);
    }

    public function test_account_locks_after_multiple_failed_attempts()
    {
        // 5 failed attempts
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/login', [
                'email' => 'test@example.com',
                'password' => 'wrongpassword',
            ]);
        }

        // 6th attempt should return 423 Locked
        $response = $this->postJson('/api/login', [
            'email' => 'test@example.com',
            'password' => 'password123', // Even correct password should fail if locked
        ]);

        $response->assertStatus(423);
        
        // Assert lock record exists
        $this->assertDatabaseHas('account_locks', [
            'email' => 'test@example.com',
        ]);
        
        // Assert alert created
        $this->assertDatabaseHas('security_alerts', [
            'email' => 'test@example.com',
            'type' => 'account_locked',
        ]);
    }

    public function test_new_device_login_creates_alert()
    {
        // First login (creates session history)
        $this->withHeaders(['User-Agent' => 'Mozilla/5.0 Windows'])
             ->postJson('/api/login', [
                 'email' => 'test@example.com',
                 'password' => 'password123',
             ]);

        // Second login from different device
        $this->withHeaders(['User-Agent' => 'Mozilla/5.0 Mac OS X'])
             ->postJson('/api/login', [
                 'email' => 'test@example.com',
                 'password' => 'password123',
             ]);

        $this->assertDatabaseHas('security_alerts', [
            'user_id' => $this->user->id,
            'type' => 'new_device_login',
        ]);
    }
}

<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\User;
use Tests\TestCase;

class LocalizationMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    public function test_api_returns_indonesian_by_default()
    {
        $response = $this->postJson('/api/login', []);
        
        // Validation error fallback in Indonesian
        $response->assertStatus(422);
        $response->assertJsonPath('message', 'Validasi gagal.');
    }

    public function test_api_returns_english_if_accept_language_is_en()
    {
        $response = $this->postJson('/api/login', [], ['Accept-Language' => 'en']);
        
        // Validation error fallback in English
        $response->assertStatus(422);
        $response->assertJsonPath('message', 'Validation error.');
    }
}

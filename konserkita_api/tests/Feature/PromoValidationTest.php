<?php
namespace Tests\Feature;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\PromoCode;

class PromoValidationTest extends TestCase
{
    use RefreshDatabase;

    public function test_promo_validation_active()
    {
        $user = User::factory()->create();
        $promo = PromoCode::factory()->create(['status' => 'active', 'quota' => 10, 'used' => 0, 'code' => 'DISC10']);
        
        $response = $this->actingAs($user)->postJson('/api/promos/validate', [
            'promo_code' => 'DISC10',
            'subtotal' => 100000,
        ]);
        $response->assertStatus(200)->assertJsonPath('data.code', 'DISC10');
    }
}
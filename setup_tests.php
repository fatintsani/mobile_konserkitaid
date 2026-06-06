<?php

$dir = __DIR__ . '/konserkita_api/tests/Feature';

$files = [
    'AuthTest.php' => <<<'EOT'
<?php
namespace Tests\Feature;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register()
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);
        $response->assertStatus(200)->assertJson(['success' => true]);
        $this->assertDatabaseHas('users', ['email' => 'test@example.com']);
    }

    public function test_user_can_login()
    {
        $user = User::factory()->create(['password' => bcrypt('password')]);
        $response = $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'password',
        ]);
        $response->assertStatus(200)->assertJsonStructure(['data' => ['token']]);
    }
}
EOT,

    'CheckoutTest.php' => <<<'EOT'
<?php
namespace Tests\Feature;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Event;
use App\Models\TicketType;

class CheckoutTest extends TestCase
{
    use RefreshDatabase;

    public function test_checkout_requires_auth()
    {
        $response = $this->postJson('/api/checkout', []);
        $response->assertStatus(401);
    }
}
EOT,

    'PromoValidationTest.php' => <<<'EOT'
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
EOT,

    'MidtransCallbackTest.php' => <<<'EOT'
<?php
namespace Tests\Feature;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MidtransCallbackTest extends TestCase
{
    use RefreshDatabase;

    public function test_midtrans_callback_invalid_signature()
    {
        $response = $this->postJson('/api/payments/midtrans/callback', [
            'order_id' => 'INV-000001',
            'status_code' => '200',
            'gross_amount' => '100000.00',
            'signature_key' => 'invalid',
            'transaction_status' => 'settlement'
        ]);
        $response->assertStatus(403);
    }
}
EOT,

    'TicketScanTest.php' => <<<'EOT'
<?php
namespace Tests\Feature;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;

class TicketScanTest extends TestCase
{
    use RefreshDatabase;

    public function test_ticket_scan_requires_role()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $response = $this->actingAs($user)->postJson('/api/tickets/scan', ['ticket_code' => 'XYZ123']);
        $response->assertStatus(403);
    }
}
EOT,

    'AdminRouteProtectionTest.php' => <<<'EOT'
<?php
namespace Tests\Feature;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;

class AdminRouteProtectionTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_cannot_access_admin()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $response = $this->actingAs($user)->getJson('/api/admin/dashboard');
        $response->assertStatus(403);
    }

    public function test_admin_can_access()
    {
        $user = User::factory()->create(['role' => 'admin']);
        $response = $this->actingAs($user)->getJson('/api/admin/dashboard');
        $response->assertStatus(200);
    }
}
EOT,

    'OrganizerRouteProtectionTest.php' => <<<'EOT'
<?php
namespace Tests\Feature;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Organizer;

class OrganizerRouteProtectionTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_cannot_access_organizer()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $response = $this->actingAs($user)->getJson('/api/organizer/dashboard');
        $response->assertStatus(403);
    }

    public function test_organizer_can_access()
    {
        $user = User::factory()->create(['role' => 'organizer']);
        Organizer::factory()->create(['user_id' => $user->id]);
        $response = $this->actingAs($user)->getJson('/api/organizer/dashboard');
        $response->assertStatus(200);
    }
}
EOT,

];

foreach ($files as $name => $content) {
    file_put_contents("$dir/$name", $content);
    echo "Written $name\n";
}

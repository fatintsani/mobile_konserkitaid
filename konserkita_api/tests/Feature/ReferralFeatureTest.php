<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Event;
use App\Models\TicketType;
use App\Models\ReferralCode;
use App\Models\Transaction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReferralFeatureTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->referrer = User::factory()->create(['role' => 'customer']);
        $this->buyer = User::factory()->create(['role' => 'customer']);
        $this->admin = User::factory()->create(['role' => 'admin']);

        $this->organizerUser = User::factory()->create(['role' => 'organizer']);
        $this->organizer = \App\Models\Organizer::create([
            'user_id' => $this->organizerUser->id,
            'name' => 'Test Organizer',
            'company_name' => 'Test Company',
            'email' => 'org@test.com',
            'phone' => '123456',
            'address' => 'Test',
            'status' => 'verified'
        ]);

        $this->category = \App\Models\EventCategory::create([
            'name' => 'Music',
            'name_en' => 'Music',
        ]);

        $this->event = Event::create([
            'organizer_id' => $this->organizer->id,
            'category_id' => $this->category->id,
            'title' => 'Test Event',
            'title_en' => 'Test Event',
            'slug' => 'test-event',
            'slug_en' => 'test-event-en',
            'description' => 'Test',
            'description_en' => 'Test',
            'date' => '2027-01-01',
            'time' => '19:00:00',
            'location' => 'Test Location',
            'status' => 'published',
        ]);
        
        $this->ticketType = TicketType::create([
            'event_id' => $this->event->id,
            'name' => 'VIP',
            'price' => 100000,
            'stock' => 100,
            'requires_seat' => false,
            'max_buy_per_transaction' => 5,
        ]);
    }

    public function test_user_can_generate_and_get_referral_code()
    {
        $response = $this->actingAs($this->referrer)->getJson('/api/referrals/my-code');

        $response->assertStatus(200)
                 ->assertJsonStructure(['success', 'data' => ['code', 'commission_value']]);
                 
        $this->assertDatabaseHas('referral_codes', [
            'user_id' => $this->referrer->id,
            'type' => 'user_referral'
        ]);
    }

    public function test_user_cannot_apply_own_referral_code()
    {
        $code = ReferralCode::create([
            'user_id' => $this->referrer->id,
            'code' => 'REF123',
        ]);

        $response = $this->actingAs($this->referrer)->postJson('/api/referrals/apply', [
            'code' => 'REF123'
        ]);

        $response->assertStatus(400)
                 ->assertJsonFragment(['message' => 'You cannot use your own referral code.']);
    }

    public function test_buyer_can_apply_valid_referral_code()
    {
        $code = ReferralCode::create([
            'user_id' => $this->referrer->id,
            'code' => 'REF123',
        ]);

        $response = $this->actingAs($this->buyer)->postJson('/api/referrals/apply', [
            'code' => 'REF123'
        ]);

        $response->assertStatus(200)
                 ->assertJsonFragment(['code' => 'REF123']);
    }

    public function test_checkout_with_referral_creates_transaction_with_referral_code_id()
    {
        $code = ReferralCode::create([
            'user_id' => $this->referrer->id,
            'code' => 'REF123',
        ]);

        $response = $this->actingAs($this->buyer)->postJson('/api/checkout', [
            'event_id' => $this->event->id,
            'tickets' => [
                ['ticket_type_id' => $this->ticketType->id, 'quantity' => 2]
            ],
            'referral_code' => 'REF123'
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('transactions', [
            'user_id' => $this->buyer->id,
            'referral_code_id' => $code->id,
        ]);
    }

    public function test_payment_success_creates_referral_conversion_and_reward()
    {
        $code = ReferralCode::create([
            'user_id' => $this->referrer->id,
            'code' => 'REF123',
            'commission_type' => 'percentage',
            'commission_value' => 10, // 10%
        ]);

        $transaction = Transaction::create([
            'user_id' => $this->buyer->id,
            'total_amount' => 200000,
            'payment_status' => 'pending',
            'referral_code_id' => $code->id,
        ]);

        $payload = [
            'order_id' => 'INV-' . str_pad($transaction->id, 6, '0', STR_PAD_LEFT),
            'status_code' => '200',
            'gross_amount' => '200000.00',
            'transaction_status' => 'settlement',
            'fraud_status' => 'accept',
        ];

        $serverKey = config('services.midtrans.server_key');
        $payload['signature_key'] = hash('sha512', $payload['order_id'] . $payload['status_code'] . $payload['gross_amount'] . $serverKey);

        $response = $this->postJson('/api/payments/midtrans/callback', $payload);
        $response->assertStatus(200);

        // 10% of 200000 is 20000
        $this->assertDatabaseHas('referral_conversions', [
            'referral_code_id' => $code->id,
            'transaction_id' => $transaction->id,
            'commission_amount' => 20000,
            'status' => 'pending'
        ]);

        $this->assertDatabaseHas('referral_rewards', [
            'user_id' => $this->referrer->id,
            'amount' => 20000,
            'status' => 'pending'
        ]);

        $this->assertDatabaseHas('referral_codes', [
            'id' => $code->id,
            'used_count' => 1
        ]);
    }

    public function test_admin_can_approve_and_mark_paid_referral_reward()
    {
        $code = ReferralCode::create([
            'user_id' => $this->referrer->id,
            'code' => 'REF123',
        ]);

        $conversion = \App\Models\ReferralConversion::create([
            'referral_code_id' => $code->id,
            'commission_amount' => 50000,
            'status' => 'pending'
        ]);

        $reward = \App\Models\ReferralReward::create([
            'user_id' => $this->referrer->id,
            'referral_conversion_id' => $conversion->id,
            'amount' => 50000,
            'status' => 'pending'
        ]);

        // Approve
        $response = $this->actingAs($this->admin)->postJson("/api/admin/referrals/rewards/{$reward->id}/approve");
        $response->assertStatus(200);
        $this->assertDatabaseHas('referral_rewards', ['id' => $reward->id, 'status' => 'approved']);

        // Mark Paid
        $response = $this->actingAs($this->admin)->postJson("/api/admin/referrals/rewards/{$reward->id}/mark-paid");
        $response->assertStatus(200);
        $this->assertDatabaseHas('referral_rewards', ['id' => $reward->id, 'status' => 'paid']);
        $this->assertNotNull($reward->fresh()->paid_at);
    }
}

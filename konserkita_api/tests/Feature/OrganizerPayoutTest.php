<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Organizer;
use App\Models\Event;
use App\Models\EventCategory;
use App\Models\TicketType;
use App\Models\Transaction;
use App\Models\TransactionItem;
use App\Models\OrganizerPayout;

class OrganizerPayoutTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['platform.platform_fee_percentage' => 10]);
    }

    public function test_organizer_can_view_balances()
    {
        $user = User::factory()->create(['role' => 'organizer']);
        $organizer = Organizer::create(['user_id' => $user->id, 'company_name' => 'Org A']);
        
        $category = EventCategory::create(['name' => 'Music', 'slug' => 'music']);
        $event = Event::create([
            'organizer_id' => $organizer->id,
            'category_id' => $category->id,
            'title' => 'Concert',
            'slug' => 'concert',
            'description' => 'Test concert',
            'date' => '2026-10-10',
            'time' => '19:00',
            'location' => 'Stadium',
            'status' => 'published',
        ]);
        
        $ticketType = TicketType::create([
            'event_id' => $event->id,
            'name' => 'VIP',
            'price' => 100000,
            'stock' => 100,
            'max_buy_per_transaction' => 4,
        ]);

        $transaction = Transaction::create([
            'user_id' => User::factory()->create()->id,
            'subtotal' => 200000,
            'total_amount' => 200000,
            'payment_status' => 'success',
        ]);

        TransactionItem::create([
            'transaction_id' => $transaction->id,
            'ticket_type_id' => $ticketType->id,
            'quantity' => 2,
            'price' => 100000,
            'subtotal' => 200000,
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/organizer/payouts/balance');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'gross_revenue' => 200000,
                    'platform_fee' => 20000,
                    'net_revenue' => 180000,
                    'total_paid_out' => 0,
                    'total_locked' => 0,
                    'available_balance' => 180000,
                ],
            ]);
    }

    public function test_organizer_can_request_payout_if_balance_sufficient()
    {
        $user = User::factory()->create(['role' => 'organizer']);
        $organizer = Organizer::create(['user_id' => $user->id, 'company_name' => 'Org B']);
        
        $category = EventCategory::create(['name' => 'Music', 'slug' => 'music']);
        $event = Event::create([
            'organizer_id' => $organizer->id,
            'category_id' => $category->id,
            'title' => 'Concert',
            'slug' => 'concert',
            'description' => 'Test concert',
            'date' => '2026-10-10',
            'time' => '19:00',
            'location' => 'Stadium',
            'status' => 'published',
        ]);
        
        $ticketType = TicketType::create([
            'event_id' => $event->id,
            'name' => 'VIP',
            'price' => 500000,
            'stock' => 100,
            'max_buy_per_transaction' => 4,
        ]);

        $transaction = Transaction::create([
            'user_id' => User::factory()->create()->id,
            'subtotal' => 500000,
            'total_amount' => 500000,
            'payment_status' => 'success',
        ]);

        TransactionItem::create([
            'transaction_id' => $transaction->id,
            'ticket_type_id' => $ticketType->id,
            'quantity' => 1,
            'price' => 500000,
            'subtotal' => 500000,
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/organizer/payouts', [
            'amount' => 400000,
            'bank_name' => 'BCA',
            'bank_account_name' => 'John Doe',
            'bank_account_number' => '1234567890',
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('organizer_payouts', [
            'organizer_id' => $organizer->id,
            'amount' => 400000,
            'status' => 'pending',
        ]);

        // Second request should fail if insufficient balance
        $response2 = $this->actingAs($user, 'sanctum')->postJson('/api/organizer/payouts', [
            'amount' => 100000, // available is 450000 - 400000 = 50000
            'bank_name' => 'BCA',
            'bank_account_name' => 'John Doe',
            'bank_account_number' => '1234567890',
        ]);

        $response2->assertStatus(400);
        $response2->assertJsonFragment(['success' => false, 'message' => 'Insufficient available balance.']);
    }
}

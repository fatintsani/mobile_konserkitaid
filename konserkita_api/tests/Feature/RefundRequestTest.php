<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Transaction;
use App\Models\Ticket;
use App\Models\Event;
use App\Models\TicketType;
use App\Models\TransactionItem;
use App\Models\EventCategory;

class RefundRequestTest extends TestCase
{
    use RefreshDatabase;

    private $user;
    private $transaction;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->user = User::factory()->create(['role' => 'customer']);

        $organizerUser = User::factory()->create(['role' => 'organizer']);
        $organizer = \App\Models\Organizer::create(['user_id' => $organizerUser->id, 'company_name' => 'Test Org', 'phone_number' => '12345']);

        $category = EventCategory::create(['name' => 'Music']);
        $event = Event::create([
            'organizer_id' => $organizer->id,
            'category_id' => $category->id,
            'title' => 'Test Event',
            'slug' => 'test-event',
            'description' => 'Test',
            'location' => 'Test',
            'date' => now()->addDays(5)->format('Y-m-d'),
            'time' => '19:00:00',
            'status' => 'published'
        ]);

        $ticketType = TicketType::create([
            'event_id' => $event->id,
            'name' => 'VIP',
            'price' => 100000,
            'stock' => 100
        ]);

        $this->transaction = Transaction::create([
            'user_id' => $this->user->id,
            'subtotal' => 100000,
            'total_amount' => 100000,
            'payment_status' => 'success'
        ]);

        TransactionItem::create([
            'transaction_id' => $this->transaction->id,
            'ticket_type_id' => $ticketType->id,
            'quantity' => 1,
            'price' => 100000,
            'subtotal' => 100000
        ]);

        Ticket::create([
            'transaction_id' => $this->transaction->id,
            'ticket_type_id' => $ticketType->id,
            'user_id' => $this->user->id,
            'ticket_code' => 'TICKET-123',
            'is_used' => false
        ]);
    }

    public function test_user_can_request_refund_for_success_transaction()
    {
        $response = $this->actingAs($this->user)->postJson('/api/refunds', [
            'transaction_id' => $this->transaction->id,
            'reason' => 'Changed my mind'
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('data.status', 'pending');
        $this->assertDatabaseHas('refunds', [
            'transaction_id' => $this->transaction->id,
            'reason' => 'Changed my mind'
        ]);
    }

    public function test_user_cannot_refund_pending_transaction()
    {
        $this->transaction->update(['payment_status' => 'pending']);

        $response = $this->actingAs($this->user)->postJson('/api/refunds', [
            'transaction_id' => $this->transaction->id,
            'reason' => 'Test'
        ]);

        $response->assertStatus(400);
        $response->assertJsonPath('message', 'Hanya transaksi yang sudah berhasil dibayar yang dapat direfund.');
    }

    public function test_user_cannot_refund_used_ticket()
    {
        $this->transaction->tickets()->update(['is_used' => true]);

        $response = $this->actingAs($this->user)->postJson('/api/refunds', [
            'transaction_id' => $this->transaction->id,
            'reason' => 'Test'
        ]);

        $response->assertStatus(400);
        $response->assertJsonPath('message', 'Tidak bisa refund karena ada tiket yang sudah digunakan.');
    }

    public function test_user_cannot_refund_transaction_twice()
    {
        $this->actingAs($this->user)->postJson('/api/refunds', [
            'transaction_id' => $this->transaction->id,
            'reason' => 'First time'
        ]);

        $response = $this->actingAs($this->user)->postJson('/api/refunds', [
            'transaction_id' => $this->transaction->id,
            'reason' => 'Second time'
        ]);

        $response->assertStatus(400);
    }
}

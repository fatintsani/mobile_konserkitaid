<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Transaction;
use App\Models\Refund;
use App\Models\Ticket;
use App\Models\Event;
use App\Models\TicketType;
use App\Models\TransactionItem;
use App\Models\EventCategory;

class AdminRefundTest extends TestCase
{
    use RefreshDatabase;

    private $admin;
    private $refund;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create(['role' => 'customer']);

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

        $transaction = Transaction::create([
            'user_id' => $user->id,
            'subtotal' => 100000,
            'total_amount' => 100000,
            'payment_status' => 'success'
        ]);

        TransactionItem::create([
            'transaction_id' => $transaction->id,
            'ticket_type_id' => $ticketType->id,
            'quantity' => 1,
            'price' => 100000,
            'subtotal' => 100000
        ]);

        Ticket::create([
            'transaction_id' => $transaction->id,
            'ticket_type_id' => $ticketType->id,
            'user_id' => $user->id,
            'ticket_code' => 'TICKET-123',
            'is_used' => false
        ]);

        $this->refund = Refund::create([
            'transaction_id' => $transaction->id,
            'user_id' => $user->id,
            'reason' => 'Test',
            'status' => 'pending',
            'refund_amount' => 100000
        ]);
    }

    public function test_admin_can_approve_refund()
    {
        $response = $this->actingAs($this->admin)->putJson("/api/admin/refunds/{$this->refund->id}/approve");

        $response->assertStatus(200);
        $this->assertDatabaseHas('refunds', [
            'id' => $this->refund->id,
            'status' => 'approved'
        ]);
        $this->assertDatabaseHas('transactions', [
            'id' => $this->refund->transaction_id,
            'payment_status' => 'refund_approved'
        ]);
    }

    public function test_admin_can_reject_refund()
    {
        $response = $this->actingAs($this->admin)->putJson("/api/admin/refunds/{$this->refund->id}/reject", [
            'admin_note' => 'Invalid reason'
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('refunds', [
            'id' => $this->refund->id,
            'status' => 'rejected',
            'admin_note' => 'Invalid reason'
        ]);
    }

    public function test_admin_can_process_approved_refund()
    {
        $this->refund->update(['status' => 'approved']);

        $response = $this->actingAs($this->admin)->putJson("/api/admin/refunds/{$this->refund->id}/process");

        $response->assertStatus(200);
        $this->assertDatabaseHas('refunds', [
            'id' => $this->refund->id,
            'status' => 'processed'
        ]);
        $this->assertDatabaseHas('transactions', [
            'id' => $this->refund->transaction_id,
            'payment_status' => 'refunded'
        ]);
        $this->assertDatabaseHas('tickets', [
            'transaction_id' => $this->refund->transaction_id,
            'is_cancelled' => true
        ]);
    }
}

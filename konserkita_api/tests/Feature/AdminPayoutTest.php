<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Organizer;
use App\Models\OrganizerPayout;

class AdminPayoutTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_approve_payout()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $organizerUser = User::factory()->create(['role' => 'organizer']);
        $organizer = Organizer::create(['user_id' => $organizerUser->id, 'company_name' => 'Org C']);

        $payout = OrganizerPayout::create([
            'organizer_id' => $organizer->id,
            'requested_by' => $organizerUser->id,
            'amount' => 100000,
            'platform_fee' => 0,
            'net_amount' => 100000,
            'bank_name' => 'BCA',
            'bank_account_name' => 'Jane Doe',
            'bank_account_number' => '0987654321',
            'status' => 'pending',
            'requested_at' => now(),
        ]);

        $response = $this->actingAs($admin, 'sanctum')->putJson("/api/admin/payouts/{$payout->id}/approve");

        $response->assertStatus(200);
        $this->assertDatabaseHas('organizer_payouts', [
            'id' => $payout->id,
            'status' => 'approved',
        ]);
        $this->assertNotNull(OrganizerPayout::find($payout->id)->approved_at);
    }

    public function test_admin_can_reject_payout()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $organizerUser = User::factory()->create(['role' => 'organizer']);
        $organizer = Organizer::create(['user_id' => $organizerUser->id, 'company_name' => 'Org D']);

        $payout = OrganizerPayout::create([
            'organizer_id' => $organizer->id,
            'requested_by' => $organizerUser->id,
            'amount' => 100000,
            'platform_fee' => 0,
            'net_amount' => 100000,
            'bank_name' => 'BCA',
            'bank_account_name' => 'Jane Doe',
            'bank_account_number' => '0987654321',
            'status' => 'pending',
            'requested_at' => now(),
        ]);

        $response = $this->actingAs($admin, 'sanctum')->putJson("/api/admin/payouts/{$payout->id}/reject", [
            'admin_note' => 'Invalid bank details',
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('organizer_payouts', [
            'id' => $payout->id,
            'status' => 'rejected',
            'admin_note' => 'Invalid bank details',
        ]);
    }

    public function test_admin_can_mark_payout_as_paid()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $organizerUser = User::factory()->create(['role' => 'organizer']);
        $organizer = Organizer::create(['user_id' => $organizerUser->id, 'company_name' => 'Org E']);

        $payout = OrganizerPayout::create([
            'organizer_id' => $organizer->id,
            'requested_by' => $organizerUser->id,
            'amount' => 100000,
            'platform_fee' => 0,
            'net_amount' => 100000,
            'bank_name' => 'BCA',
            'bank_account_name' => 'Jane Doe',
            'bank_account_number' => '0987654321',
            'status' => 'approved',
            'requested_at' => now(),
        ]);

        $response = $this->actingAs($admin, 'sanctum')->putJson("/api/admin/payouts/{$payout->id}/mark-paid", [
            'admin_note' => 'Transfer success ref 123',
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('organizer_payouts', [
            'id' => $payout->id,
            'status' => 'paid',
            'admin_note' => 'Transfer success ref 123',
        ]);
        $this->assertNotNull(OrganizerPayout::find($payout->id)->paid_at);
    }
}

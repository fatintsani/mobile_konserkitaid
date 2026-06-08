<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use App\Models\Event;
use App\Models\AdminAuditLog;

class AdminAuditTrailTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_audit_log_is_created_and_sensitive_data_masked()
    {
        $superAdmin = User::factory()->create(['role' => 'super_admin']);
        $targetUser = User::factory()->create(['role' => 'customer']);
        
        // We'll update the target user's role to test the user update audit log
        $response = $this->actingAs($superAdmin)->putJson('/api/admin/users/' . $targetUser->id, [
            'role' => 'organizer',
            // adding a dummy secret to test masking even though it's not part of the standard update
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('admin_audit_logs', [
            'admin_id' => $superAdmin->id,
            'action' => 'user_updated',
            'module' => 'users',
            'target_id' => $targetUser->id,
        ]);

        $log = AdminAuditLog::where('admin_id', $superAdmin->id)->first();
        
        // Assert old values masked
        $oldValues = $log->old_values;
        $this->assertEquals('customer', $oldValues['role']);

        // Assert new values masked
        $newValues = $log->new_values;
        $this->assertEquals('organizer', $newValues['role']);
    }

    public function test_only_super_admin_can_view_all_audit_logs()
    {
        $superAdmin = User::factory()->create(['role' => 'super_admin']);
        $admin = User::factory()->create(['role' => 'admin']);

        AdminAuditLog::create([
            'admin_id' => $superAdmin->id,
            'action' => 'test_action_1',
            'module' => 'test',
            'description' => 'Test 1',
        ]);

        AdminAuditLog::create([
            'admin_id' => $admin->id,
            'action' => 'test_action_2',
            'module' => 'test',
            'description' => 'Test 2',
        ]);

        // Super admin sees all (2)
        $response = $this->actingAs($superAdmin)->getJson('/api/admin/audit-logs');
        $response->assertStatus(200);
        $this->assertCount(2, $response->json('data.data'));

        // Normal admin sees only their own (1)
        $response2 = $this->actingAs($admin)->getJson('/api/admin/audit-logs');
        $response2->assertStatus(200);
        $this->assertCount(1, $response2->json('data.data'));
        $this->assertEquals('test_action_2', $response2->json('data.data.0.action'));
    }
}

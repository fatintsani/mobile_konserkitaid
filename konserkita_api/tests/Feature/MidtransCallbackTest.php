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
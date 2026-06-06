<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // For MySQL/MariaDB, alter enum natively. 
        // For SQLite (testing/local), it might ignore ENUM alterations or fail, so we catch it.
        try {
            DB::statement("ALTER TABLE transactions MODIFY COLUMN payment_status ENUM('pending', 'success', 'failed', 'expired', 'refund_approved', 'refunded') DEFAULT 'pending'");
        } catch (\Exception $e) {
            // Ignore if driver doesn't support it (e.g. SQLite testing)
        }
    }

    public function down(): void
    {
        try {
            DB::statement("ALTER TABLE transactions MODIFY COLUMN payment_status ENUM('pending', 'success', 'failed', 'expired') DEFAULT 'pending'");
        } catch (\Exception $e) {
            // Ignore
        }
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        try {
            DB::statement("ALTER TABLE events MODIFY COLUMN status ENUM('draft', 'pending', 'published', 'cancelled', 'completed') DEFAULT 'pending'");
        } catch (\Exception $e) {
            // Ignore for SQLite
        }
    }

    public function down(): void
    {
        try {
            DB::statement("ALTER TABLE events MODIFY COLUMN status ENUM('draft', 'published', 'cancelled', 'completed') DEFAULT 'draft'");
        } catch (\Exception $e) {
            // Ignore
        }
    }
};

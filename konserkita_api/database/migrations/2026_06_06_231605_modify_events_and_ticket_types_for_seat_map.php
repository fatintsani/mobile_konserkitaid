<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->boolean('is_numbered_seating')->default(false)->after('status');
        });

        Schema::table('ticket_types', function (Blueprint $table) {
            $table->boolean('requires_seat')->default(false)->after('max_buy_per_transaction');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->dropColumn('is_numbered_seating');
        });

        Schema::table('ticket_types', function (Blueprint $table) {
            $table->dropColumn('requires_seat');
        });
    }
};

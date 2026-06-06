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
        Schema::create('organizer_payouts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organizer_id')->constrained('organizers')->cascadeOnDelete();
            $table->foreignId('event_id')->nullable()->constrained('events')->cascadeOnDelete();
            $table->foreignId('requested_by')->constrained('users')->cascadeOnDelete();
            $table->decimal('amount', 12, 2);
            $table->decimal('platform_fee', 12, 2)->default(0);
            $table->decimal('net_amount', 12, 2);
            $table->string('bank_name');
            $table->string('bank_account_name');
            $table->string('bank_account_number');
            $table->enum('status', ['pending', 'approved', 'rejected', 'paid'])->default('pending');
            $table->text('admin_note')->nullable();
            $table->timestamp('requested_at')->useCurrent();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('organizer_payouts');
    }
};

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
        Schema::create('account_recovery_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('email');
            $table->enum('type', [
                'password_reset',
                'account_recovery',
                'email_change',
                'two_factor_reset'
            ]);
            $table->enum('status', [
                'pending',
                'approved',
                'rejected',
                'expired',
                'completed'
            ])->default('pending');
            $table->string('token_hash')->nullable();
            $table->timestamp('expires_at');
            $table->string('ip_address')->nullable();
            $table->text('user_agent')->nullable();
            $table->text('admin_note')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('account_recovery_requests');
    }
};

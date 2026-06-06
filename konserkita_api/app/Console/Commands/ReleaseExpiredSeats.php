<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\SeatReservation;
use Illuminate\Support\Facades\Log;

class ReleaseExpiredSeats extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'seats:release-expired';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Release seats that have been held longer than their expiration time';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $expiredCount = SeatReservation::where('status', 'held')
            ->whereNotNull('hold_expires_at')
            ->where('hold_expires_at', '<', now())
            // Only release if there is no pending transaction linked
            // Wait, if there is a transaction, Midtrans expiration handles it.
            // If the user never checked out, transaction_id is null.
            ->whereNull('transaction_id')
            ->update([
                'status' => 'available',
                'hold_expires_at' => null,
                'user_id' => null,
            ]);

        $this->info("Released {$expiredCount} expired seat holds.");
        if ($expiredCount > 0) {
            Log::info("Released {$expiredCount} expired seat holds.");
        }
    }
}

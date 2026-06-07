<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\OrganizerLimit;

class ResetOrganizerLimits extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'subscriptions:reset-limits';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Reset monthly usage limits for organizers';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        // This should run on the 1st of every month
        OrganizerLimit::query()->update([
            'current_month_events' => 0,
            'current_month_tickets_sold' => 0,
            'reset_at' => now()
        ]);

        $this->info('Organizer limits reset successfully.');
    }
}

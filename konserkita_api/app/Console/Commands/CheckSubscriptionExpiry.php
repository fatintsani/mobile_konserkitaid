<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\OrganizerSubscription;
use App\Models\Notification;
use Carbon\Carbon;

class CheckSubscriptionExpiry extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'subscriptions:check-expiry';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Check and update expired organizer subscriptions';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $now = Carbon::now();

        // Check expiring trials
        $expiringTrials = OrganizerSubscription::where('status', 'trialing')
            ->where('trial_ends_at', '<', $now->copy()->addDays(3))
            ->where('trial_ends_at', '>', $now)
            ->get();

        foreach ($expiringTrials as $sub) {
            Notification::firstOrCreate([
                'user_id' => $sub->organizer->user_id,
                'title' => 'Trial Expiring Soon',
                'message' => 'Your trial ends in less than 3 days. Upgrade to keep publishing events.',
                'type' => 'subscription'
            ]);
        }

        // Check expired trials
        $expiredTrials = OrganizerSubscription::where('status', 'trialing')
            ->where('trial_ends_at', '<=', $now)
            ->get();

        foreach ($expiredTrials as $sub) {
            $sub->update(['status' => 'expired']);
            Notification::create([
                'user_id' => $sub->organizer->user_id,
                'title' => 'Trial Expired',
                'message' => 'Your trial has expired. Upgrade your plan to continue using the platform.',
                'type' => 'subscription'
            ]);
        }

        // Check expired active subscriptions
        $expiredSubs = OrganizerSubscription::where('status', 'active')
            ->where('ends_at', '<=', $now)
            ->get();

        foreach ($expiredSubs as $sub) {
            $sub->update(['status' => 'past_due']);
            Notification::create([
                'user_id' => $sub->organizer->user_id,
                'title' => 'Subscription Expired',
                'message' => 'Your subscription has expired. Please renew to keep publishing events.',
                'type' => 'subscription'
            ]);
        }

        $this->info('Checked subscriptions successfully.');
    }
}

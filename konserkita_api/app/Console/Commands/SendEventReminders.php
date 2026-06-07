<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('app:send-event-reminders')]
#[Description('Command description')]
class SendEventReminders extends Command
{
    /**
     * Execute the console command.
     */
    public function handle()
    {
        $tomorrow = \Carbon\Carbon::tomorrow()->format('Y-m-d');
        
        $this->info("Looking for events on {$tomorrow}");

        $events = \App\Models\Event::where('date', $tomorrow)
            ->where('status', 'upcoming')
            ->get();

        if ($events->isEmpty()) {
            $this->info('No events found for tomorrow.');
            return;
        }

        foreach ($events as $event) {
            $this->info("Processing event: {$event->title}");

            // Get users who bought valid tickets for this event
            $users = \App\Models\User::whereHas('tickets', function ($q) use ($event) {
                $q->whereHas('ticketType', function ($q2) use ($event) {
                    $q2->where('event_id', $event->id);
                })->where('is_cancelled', false);
            })->get();

            $count = 0;
            foreach ($users as $user) {
                // Check if reminder was already sent
                $alreadySent = \App\Models\Notification::where('user_id', $user->id)
                    ->where('type', 'reminder')
                    ->where('title', 'like', "%{$event->title}%")
                    ->exists();

                if (!$alreadySent) {
                    \App\Models\Notification::create([
                        'user_id' => $user->id,
                        'title' => 'Event Reminder',
                        'message' => "Don't forget! '{$event->title}' is happening tomorrow at {$event->time} in {$event->location}.",
                        'type' => 'reminder'
                    ]);
                    $count++;
                }
            }

            $this->info("Sent reminders to {$count} users for event {$event->title}.");
        }

        $this->info('Event reminders process completed.');
    }
}

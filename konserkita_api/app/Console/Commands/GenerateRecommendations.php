<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Models\Event;
use App\Models\UserEventInteraction;
use App\Models\UserPreference;
use App\Models\EventRecommendation;

class GenerateRecommendations extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'recommendations:generate';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generate personalized event recommendations for all active users';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Starting recommendation generation...');

        $users = User::all();
        $events = Event::with('category')->where('status', 'published')
            ->whereDate('date', '>=', now())
            ->get();

        foreach ($users as $user) {
            $this->generateForUser($user, $events);
        }

        $this->info('Recommendation generation completed!');
    }

    private function generateForUser(User $user, $allEvents)
    {
        // 1. Get user interactions
        $interactions = UserEventInteraction::where('user_id', $user->id)
            ->with('event.category')
            ->get();

        // 2. Get user preferences
        $preferences = UserPreference::where('user_id', $user->id)->first();

        // Build a profile based on interactions
        $categoryScores = [];
        $locationScores = [];
        $purchasedEventIds = [];

        foreach ($interactions as $interaction) {
            $event = $interaction->event;
            if (!$event) continue;

            if ($interaction->interaction_type === 'purchase') {
                $purchasedEventIds[] = $event->id;
            }

            // Score categories
            $catId = $event->category_id;
            if (!isset($categoryScores[$catId])) $categoryScores[$catId] = 0;
            $categoryScores[$catId] += $interaction->weight;

            // Score locations
            $loc = $event->location;
            if (!isset($locationScores[$loc])) $locationScores[$loc] = 0;
            $locationScores[$loc] += $interaction->weight;
        }

        // Add explicit preferences weight
        if ($preferences) {
            if ($preferences->preferred_categories) {
                foreach ($preferences->preferred_categories as $cat) {
                    // +20 explicit weight for preferred categories
                    if (!isset($categoryScores[$cat])) $categoryScores[$cat] = 0;
                    $categoryScores[$cat] += 20; 
                }
            }
            if ($preferences->preferred_locations) {
                foreach ($preferences->preferred_locations as $loc) {
                    if (!isset($locationScores[$loc])) $locationScores[$loc] = 0;
                    $locationScores[$loc] += 20; 
                }
            }
        }

        $recommendations = [];

        // 3. Score all available events
        foreach ($allEvents as $event) {
            // Skip already purchased
            if (in_array($event->id, $purchasedEventIds)) continue;

            // Enforce price preferences if set
            if ($preferences) {
                $minPrice = $event->ticketTypes->min('price') ?? 0;
                if ($preferences->min_price && $minPrice < $preferences->min_price) continue;
                if ($preferences->max_price && $minPrice > $preferences->max_price) continue;
            }

            $score = 0;
            $reasons = [];

            // Category match
            if (isset($categoryScores[$event->category_id])) {
                $score += $categoryScores[$event->category_id];
                $reasons[] = 'Kategori ' . ($event->category->name ?? 'favorit');
            }

            // Location match
            if (isset($locationScores[$event->location])) {
                $score += $locationScores[$event->location];
                $reasons[] = 'Lokasi ' . $event->location;
            }

            // Default fallback if no interactions and just random events
            if ($score == 0) {
                $score = rand(1, 5); // Add small random base score to ensure some recommendations
                $reasons[] = 'Rekomendasi Populer';
            }

            $recommendations[] = [
                'event_id' => $event->id,
                'score' => $score,
                'reason' => 'Berdasarkan ' . implode(' & ', $reasons),
            ];
        }

        // Sort by score
        usort($recommendations, function($a, $b) {
            return $b['score'] <=> $a['score'];
        });

        // Save top 10
        EventRecommendation::where('user_id', $user->id)->delete(); // clear old

        $top = array_slice($recommendations, 0, 10);
        foreach ($top as $rec) {
            EventRecommendation::create([
                'user_id' => $user->id,
                'event_id' => $rec['event_id'],
                'score' => $rec['score'],
                'reason' => $rec['reason'],
            ]);
        }
    }
}

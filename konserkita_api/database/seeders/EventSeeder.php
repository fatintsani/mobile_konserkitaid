<?php

namespace Database\Seeders;

use App\Models\Event;
use App\Models\EventCategory;
use App\Models\Organizer;
use App\Models\TicketType;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class EventSeeder extends Seeder
{
    public function run(): void
    {
        $organizer = Organizer::first();
        $category = EventCategory::where('name', 'Music Festival')->first();

        if ($organizer && $category) {
            $event = Event::create([
                'organizer_id' => $organizer->id,
                'category_id' => $category->id,
                'title' => 'KonserKita Summer Festival 2026',
                'slug' => Str::slug('KonserKita Summer Festival 2026'),
                'description' => 'The biggest summer festival of the year featuring top artists from around the world.',
                'date' => Carbon::now()->addMonths(2)->toDateString(),
                'time' => '15:00:00',
                'location' => 'Gelora Bung Karno Stadium, Jakarta',
                'status' => 'published',
            ]);

            TicketType::create([
                'event_id' => $event->id,
                'name' => 'Festival (Standing)',
                'price' => 500000,
                'stock' => 5000,
                'max_buy_per_transaction' => 4,
            ]);

            TicketType::create([
                'event_id' => $event->id,
                'name' => 'VIP (Seated)',
                'price' => 1500000,
                'stock' => 1000,
                'max_buy_per_transaction' => 2,
            ]);
        }
    }
}

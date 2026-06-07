<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

use App\Models\Venue;
use App\Models\Event;
use App\Models\TicketType;
use App\Models\EventSeatMap;

class SeatMapSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Ambil Venue yang baru saja Anda buat di Admin Panel
        $venue = Venue::latest()->first();
        
        if (!$venue) {
            $this->command->error('Venue belum ada! Silakan buat Venue dan Section-nya dulu di Admin Panel.');
            return;
        }

        // 2. Ambil Event terakhir yang ada di database untuk diujicoba
        $event = Event::latest()->first();
        
        if (!$event) {
            $this->command->error('Belum ada Event sama sekali. Buat Event dulu di aplikasi Organizer.');
            return;
        }

        // 3. Pasangkan Venue ini ke Event tersebut
        EventSeatMap::updateOrCreate(
            ['event_id' => $event->id],
            ['venue_id' => $venue->id]
        );

        // 4. Ubah Event ini menjadi "Numbered Seating"
        $event->update([
            'is_numbered_seating' => true
        ]);

        // 5. Ubah semua Ticket Type di Event ini menjadi wajib pilih kursi
        TicketType::where('event_id', $event->id)->update([
            'requires_seat' => true
        ]);

        $this->command->info("Sukses! Event '{$event->title}' sekarang menggunakan Venue '{$venue->name}' dengan sistem kursi bernomor.");
        $this->command->info("Silakan buka aplikasi Mobile dan klik event '{$event->title}' untuk mencoba Pilih Kursi.");
    }
}

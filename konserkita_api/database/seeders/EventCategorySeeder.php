<?php

namespace Database\Seeders;

use App\Models\EventCategory;
use Illuminate\Database\Seeder;

class EventCategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name' => 'Music Festival', 'icon' => 'music_note'],
            ['name' => 'Solo Concert', 'icon' => 'mic'],
            ['name' => 'K-Pop', 'icon' => 'star'],
            ['name' => 'Classical', 'icon' => 'piano'],
            ['name' => 'Jazz', 'icon' => 'saxophone'],
        ];

        foreach ($categories as $category) {
            EventCategory::create($category);
        }
    }
}

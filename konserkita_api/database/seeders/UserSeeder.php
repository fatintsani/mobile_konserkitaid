<?php

namespace Database\Seeders;

use App\Models\Organizer;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Admin
        User::create([
            'name' => 'Super Admin',
            'email' => 'admin@konserkita.com',
            'password' => Hash::make('password'),
            'role' => 'super_admin',
        ]);

        // Organizer
        $organizerUser = User::create([
            'name' => 'KonserKita Organizer',
            'email' => 'organizer@konserkita.com',
            'password' => Hash::make('password'),
            'role' => 'organizer',
        ]);

        Organizer::create([
            'user_id' => $organizerUser->id,
            'company_name' => 'KonserKita Official',
            'description' => 'The official organizer for KonserKita exclusive events.',
        ]);

        // Customer
        User::create([
            'name' => 'John Doe',
            'email' => 'customer@konserkita.com',
            'password' => Hash::make('password'),
            'role' => 'customer',
        ]);
    }
}

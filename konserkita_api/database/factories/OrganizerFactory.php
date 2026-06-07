<?php

namespace Database\Factories;

use App\Models\Organizer;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class OrganizerFactory extends Factory
{
    protected $model = Organizer::class;

    public function definition(): array
    {
        $companyName = $this->faker->company();
        return [
            'user_id' => User::factory(),
            'company_name' => $companyName,
            'public_name' => $companyName,
            'slug' => Str::slug($companyName),
            'status' => 'pending',
            'verification_badge' => false,
        ];
    }
}

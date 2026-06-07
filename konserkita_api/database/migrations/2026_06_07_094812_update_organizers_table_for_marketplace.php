<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('organizers', function (Blueprint $table) {
            $table->string('slug')->unique()->nullable();
            $table->string('public_name')->nullable();
            $table->string('cover_image')->nullable();
            $table->string('instagram_url')->nullable();
            $table->text('description_en')->nullable();
            $table->decimal('rating_average', 3, 2)->default(0);
            $table->integer('total_reviews')->default(0);
            $table->integer('total_events')->default(0);
            $table->integer('total_followers')->default(0);
            $table->boolean('verification_badge')->default(false);
            $table->enum('status', ['pending', 'verified', 'rejected', 'suspended'])->default('pending');
        });

        // Generate slugs for existing organizers
        DB::table('organizers')->get()->each(function ($org) {
            $slug = \Illuminate\Support\Str::slug($org->company_name);
            // Ensure unique
            $count = DB::table('organizers')->where('slug', $slug)->count();
            if ($count > 0) {
                $slug = $slug . '-' . $org->id;
            }
            DB::table('organizers')->where('id', $org->id)->update([
                'slug' => $slug,
                'public_name' => $org->company_name,
                'status' => 'verified',
                'verification_badge' => true
            ]);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('organizers', function (Blueprint $table) {
            $table->dropColumn([
                'slug',
                'public_name',
                'cover_image',
                'instagram_url',
                'description_en',
                'rating_average',
                'total_reviews',
                'total_events',
                'total_followers',
                'verification_badge',
                'status'
            ]);
        });
    }
};

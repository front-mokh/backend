<?php

namespace Database\Seeders;

use App\Enums\ApplicationStatus;
use App\Models\Announcement;
use App\Models\Application;
use App\Models\BrandProfile;
use App\Models\Category;
use App\Models\CreatorProfile;
use App\Models\DeliverableType;
use App\Models\InfluencerTier;
use App\Models\Platform;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create Brand User
        $brandUser = User::firstOrCreate(
            ['email' => 'brand@email.com'],
            [
                'password' => Hash::make('123456'),
                'type' => 'brand',
                'email_verified_at' => now(),
                'onboarding_completed_at' => now(),
            ]
        );

        if (!$brandUser->brandProfile) {
            BrandProfile::create([
                'user_id' => $brandUser->id,
                'name' => 'Demo Brand',
                'description' => 'A premium brand looking for top influencers.',
                'website' => 'https://example.com',
                'phone' => '1234567890',
                'location' => 'Algiers, Algeria',
                'logo' => $this->getRandomImage('logos'),
            ]);
        }

        // Add Social Links for Brand
        if ($brandUser->socialLinks()->count() === 0) {
            $brandUser->socialLinks()->createMany([
                ['url' => 'https://instagram.com/demobrand', 'is_verified' => true],
                ['url' => 'https://linkedin.com/company/demobrand', 'is_verified' => true],
                ['url' => 'https://twitter.com/demobrand', 'is_verified' => false],
            ]);
        }

        // 2. Create Creator User
        $creatorUser = User::firstOrCreate(
            ['email' => 'creator@email.com'],
            [
                'password' => Hash::make('123456'),
                'type' => 'creator',
                'email_verified_at' => now(),
                'onboarding_completed_at' => now(),
            ]
        );

        if (!$creatorUser->creatorProfile) {
            CreatorProfile::create([
                'user_id' => $creatorUser->id,
                'first_name' => 'Demo',
                'last_name' => 'Creator',
                'nickname' => 'DemoCreator',
                'bio' => 'Content creator passionate about tech and lifestyle.',
                'phone' => '0987654321',
                'profile_picture' => $this->getRandomImage('profile-pictures'),
            ]);
        }

        // 3. Create Random Creators
        $creators = User::factory(10)->create([
            'type' => 'creator',
            'email_verified_at' => now(),
            'onboarding_completed_at' => now(),
        ]);

        foreach ($creators as $creator) {
            CreatorProfile::create([
                'user_id' => $creator->id,
                'first_name' => fake()->firstName(),
                'last_name' => fake()->lastName(),
                'nickname' => fake()->userName(),
                'bio' => fake()->sentence(),
                'phone' => fake()->phoneNumber(),
                'profile_picture' => $this->getRandomImage('profile-pictures'),
            ]);
        }

        // 4. Create Announcements for Brand
        $categories = Category::all();
        $platforms = Platform::all();
        $deliverables = DeliverableType::all();
        $tiers = InfluencerTier::all();

        for ($i = 0; $i < 5; $i++) {
            $announcement = Announcement::create([
                'user_id' => $brandUser->id,
                'category_id' => $categories->random()->id,
                'title' => fake()->sentence(4),
                'description' => fake()->paragraph(),
                'budget_min' => fake()->numberBetween(10000, 50000),
                'budget_max' => fake()->numberBetween(60000, 100000),
                'deadline' => now()->addDays(fake()->numberBetween(5, 30)),
                'delivery_date' => now()->addDays(fake()->numberBetween(35, 60)),
                'duration' => fake()->numberBetween(7, 30),
                'target_audience' => fake()->word(),
                'requirements' => fake()->sentence(),
                'min_followers' => fake()->numberBetween(1000, 50000),
                'influencer_tier_id' => $tiers->random()->id,
                'thumbnail' => $this->getRandomImage('announcements/thumbnails'),
                'status' => 'open',
            ]);

            $announcement->platforms()->attach($platforms->random(2));
            $announcement->deliverables()->attach($deliverables->random(2), ['quantity' => 1]);

            // 5. Create Applications for Announcement
            foreach ($creators->random(fake()->numberBetween(2, 5)) as $applicant) {
                Application::create([
                    'announcement_id' => $announcement->id,
                    'user_id' => $applicant->id,
                    'message' => fake()->paragraph(),
                    'proposed_budget' => fake()->numberBetween(10000, 80000),
                    'status' => fake()->randomElement(['pending', 'accepted', 'rejected']),
                ]);
            }
        }
    }

    private function getRandomImage(string $directory): ?string
    {
        $files = Storage::disk('public')->files($directory);
        return !empty($files) ? $files[array_rand($files)] : null;
    }
}

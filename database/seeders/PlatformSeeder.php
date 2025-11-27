<?php

namespace Database\Seeders;

use App\Models\DeliverableType;
use App\Models\Platform;
use Illuminate\Database\Seeder;

class PlatformSeeder extends Seeder
{
    public function run(): void
    {
        $platforms = [
            ['name' => 'Instagram', 'icon_name' => 'logo-instagram'],
            ['name' => 'TikTok', 'icon_name' => 'logo-tiktok'],
            ['name' => 'YouTube', 'icon_name' => 'logo-youtube'],
            ['name' => 'Snapchat', 'icon_name' => 'logo-snapchat'],
            ['name' => 'Facebook', 'icon_name' => 'logo-facebook'],
            ['name' => 'LinkedIn', 'icon_name' => 'logo-linkedin'],
            ['name' => 'Twitter / X', 'icon_name' => 'logo-twitter'],
        ];

        foreach ($platforms as $platform) {
            Platform::firstOrCreate(['name' => $platform['name']], $platform);
        }

        $deliverables = [
            ['name' => 'Post', 'icon_name' => 'image-outline'],
            ['name' => 'Story', 'icon_name' => 'time-outline'],
            ['name' => 'Reel / TikTok', 'icon_name' => 'videocam-outline'],
            ['name' => 'Video YouTube', 'icon_name' => 'play-circle-outline'],
            ['name' => 'Live', 'icon_name' => 'radio-outline'],
        ];

        foreach ($deliverables as $deliverable) {
            DeliverableType::firstOrCreate(['name' => $deliverable['name']], $deliverable);
        }
    }
}

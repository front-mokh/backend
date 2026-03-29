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

        $deliverablesByPlatform = [
            'Instagram' => [
                ['name' => 'Post', 'icon_name' => 'image-outline'],
                ['name' => 'Story', 'icon_name' => 'time-outline'],
                ['name' => 'Reel', 'icon_name' => 'videocam-outline'],
                ['name' => 'Live', 'icon_name' => 'radio-outline'],
            ],
            'TikTok' => [
                ['name' => 'Video', 'icon_name' => 'videocam-outline'],
                ['name' => 'Story', 'icon_name' => 'time-outline'],
                ['name' => 'Live', 'icon_name' => 'radio-outline'],
            ],
            'YouTube' => [
                ['name' => 'Video', 'icon_name' => 'play-circle-outline'],
                ['name' => 'Short', 'icon_name' => 'videocam-outline'],
                ['name' => 'Live', 'icon_name' => 'radio-outline'],
                ['name' => 'Community Post', 'icon_name' => 'chatbox-outline'],
            ],
            'Snapchat' => [
                ['name' => 'Snap', 'icon_name' => 'camera-outline'],
                ['name' => 'Story', 'icon_name' => 'time-outline'],
            ],
            'Facebook' => [
                ['name' => 'Post', 'icon_name' => 'image-outline'],
                ['name' => 'Story', 'icon_name' => 'time-outline'],
                ['name' => 'Video', 'icon_name' => 'play-circle-outline'],
                ['name' => 'Live', 'icon_name' => 'radio-outline'],
            ],
            'LinkedIn' => [
                ['name' => 'Post', 'icon_name' => 'document-text-outline'],
                ['name' => 'Article', 'icon_name' => 'newspaper-outline'],
                ['name' => 'Video', 'icon_name' => 'play-circle-outline'],
            ],
            'Twitter / X' => [
                ['name' => 'Post', 'icon_name' => 'chatbubble-outline'],
                ['name' => 'Thread', 'icon_name' => 'chatbubbles-outline'],
                ['name' => 'Video', 'icon_name' => 'play-circle-outline'],
            ]
        ];

        foreach ($deliverablesByPlatform as $platformName => $deliverables) {
            $platform = Platform::where('name', $platformName)->first();
            if ($platform) {
                foreach ($deliverables as $deliverable) {
                    $deliverable['platform_id'] = $platform->id;
                    DeliverableType::firstOrCreate(
                        ['name' => $deliverable['name'], 'platform_id' => $platform->id],
                        $deliverable
                    );
                }
            }
        }
    }
}

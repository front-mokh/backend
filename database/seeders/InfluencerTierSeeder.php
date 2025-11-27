<?php

namespace Database\Seeders;

use App\Models\InfluencerTier;
use Illuminate\Database\Seeder;

class InfluencerTierSeeder extends Seeder
{
    public function run(): void
    {
        $tiers = [
            ['name' => 'Nano', 'min_followers' => 1000, 'max_followers' => 10000],
            ['name' => 'Micro', 'min_followers' => 10000, 'max_followers' => 50000],
            ['name' => 'Macro', 'min_followers' => 50000, 'max_followers' => 500000],
            ['name' => 'Mega', 'min_followers' => 500000, 'max_followers' => null],
            ['name' => 'All', 'min_followers' => 0, 'max_followers' => null],
        ];

        foreach ($tiers as $tier) {
            InfluencerTier::create($tier);
        }
    }
}

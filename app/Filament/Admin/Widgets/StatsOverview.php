<?php

namespace App\Filament\Admin\Widgets;

use App\Enums\UserType;
use App\Models\Announcement;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends BaseWidget
{
    protected function getStats(): array
    {
        return [
            Stat::make('Influencers', User::where('type', UserType::CREATOR)->count())
                ->description('Total number of influencers')
                ->color('success'),
            Stat::make('Brands', User::where('type', UserType::BRAND)->count())
                ->description('Total number of brands')
                ->color('warning'),
            Stat::make('Announcements', Announcement::count())
                ->description('Total number of announcements')
                ->color('primary'),
        ];
    }
}

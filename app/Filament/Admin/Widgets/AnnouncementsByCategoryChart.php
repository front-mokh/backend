<?php

namespace App\Filament\Admin\Widgets;

use App\Models\Announcement;
use Filament\Widgets\ChartWidget;
// use Flowbite\Filament\Concerns\Has "); // Removed incorrect use statement

class AnnouncementsByCategoryChart extends ChartWidget
{
    protected static ?string $heading = 'Announcements by Category';

    protected static ?int $sort = 4;

    protected function getData(): array
    {
        $categories = Announcement::query()
            ->join('categories', 'announcements.category_id', '=', 'categories.id')
            ->selectRaw('categories.name as category_name, count(*) as count')
            ->groupBy('categories.name')
            ->pluck('count', 'category_name')
            ->toArray();

        return [
            'labels' => array_keys($categories),
            'datasets' => [
                [
                    'data' => array_values($categories),
                    'backgroundColor' => [
                        '#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF', '#FF9F40'
                    ],
                    'hoverOffset' => 4,
                ],
            ],
        ];
    }

    protected function getType(): string
    {
        return 'pie';
    }
}

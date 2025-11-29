<?php

namespace App\Filament\Admin\Widgets;

use App\Filament\Admin\Resources\AnnouncementResource;
use App\Models\Announcement;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

class LatestAnnouncementsWidget extends BaseWidget
{
    protected static ?int $sort = 2;
    
    protected int | string | array $columnSpan = 'full';


    public function table(Table $table): Table
    {
        return $table
            ->query(Announcement::query()->latest()->limit(5))
            ->columns([
                Tables\Columns\TextColumn::make('title'),
                Tables\Columns\TextColumn::make('user.email')->label('Brand'),
                Tables\Columns\TextColumn::make('created_at')->since(),
            ])
            ->actions([
                Tables\Actions\Action::make('View')
                    ->url(fn (Announcement $record): string => AnnouncementResource::getUrl('edit', ['record' => $record])),
            ]);
    }
}

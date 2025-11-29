<?php

namespace App\Filament\Admin\Resources\CreatorProfileResource\Pages;

use App\Filament\Admin\Resources\CreatorProfileResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListCreatorProfiles extends ListRecords
{
    protected static string $resource = CreatorProfileResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}

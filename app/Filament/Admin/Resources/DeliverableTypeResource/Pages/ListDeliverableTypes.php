<?php

namespace App\Filament\Admin\Resources\DeliverableTypeResource\Pages;

use App\Filament\Admin\Resources\DeliverableTypeResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListDeliverableTypes extends ListRecords
{
    protected static string $resource = DeliverableTypeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}

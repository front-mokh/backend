<?php

namespace App\Filament\Admin\Resources\DeliverableTypeResource\Pages;

use App\Filament\Admin\Resources\DeliverableTypeResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditDeliverableType extends EditRecord
{
    protected static string $resource = DeliverableTypeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}

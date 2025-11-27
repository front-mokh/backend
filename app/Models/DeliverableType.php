<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeliverableType extends Model
{
    protected $fillable = ['name', 'icon_name'];

    public function announcements()
    {
        return $this->belongsToMany(Announcement::class, 'announcement_deliverable')
                    ->withPivot('quantity');
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeliverableType extends Model
{
    protected $fillable = ['platform_id', 'name', 'icon_name'];

    public function platform()
    {
        return $this->belongsTo(Platform::class);
    }

    public function announcements()
    {
        return $this->belongsToMany(Announcement::class, 'announcement_deliverable')
                    ->withPivot('quantity');
    }
}

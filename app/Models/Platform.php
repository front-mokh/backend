<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Platform extends Model
{
    protected $fillable = ['name', 'icon_name'];

    public function announcements()
    {
        return $this->belongsToMany(Announcement::class, 'announcement_platform');
    }

    public function deliverableTypes()
    {
        return $this->hasMany(DeliverableType::class);
    }
}

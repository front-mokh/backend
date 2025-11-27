<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InfluencerTier extends Model
{
    protected $fillable = ['name', 'min_followers', 'max_followers'];

    public function announcements()
    {
        return $this->hasMany(Announcement::class);
    }
}

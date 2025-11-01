<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CreatorProfile extends Model
{
    protected $fillable = [
        'user_id',
        'first_name',
        'last_name',
        'bio',
        'instagram_handle',
        'tiktok_handle',
        'profile_picture',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

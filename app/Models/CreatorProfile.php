<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CreatorProfile extends Model
{
    protected $fillable = [
        'user_id',
        'first_name',
        'last_name',
        'nickname',
        'bio',
        'phone',
        'profile_picture',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function getProfilePictureAttribute($value)
    {
        return $value ? asset('storage/' . $value) : null;
    }
}
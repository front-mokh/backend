<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BrandProfile extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'description',
        'website',
        'logo',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

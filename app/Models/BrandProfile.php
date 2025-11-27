<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BrandProfile extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'phone',
        'location',
        'description',
        'website',
        'logo',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function industries()
    {
        return $this->belongsToMany(Industry::class, 'brand_profile_industry');
    }

    public function getLogoAttribute($value)
    {
        return $value ? asset('storage/' . $value) : null;
    }
}

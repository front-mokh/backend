<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Industry extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'description'];

    public function brandProfiles()
    {
        return $this->belongsToMany(BrandProfile::class, 'brand_profile_industry');
    }
}

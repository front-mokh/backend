<?php

namespace App\Models;

use Laravel\Sanctum\HasApiTokens;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use App\Enums\UserType;
use App\Models\BrandProfile;
use App\Models\CreatorProfile;
use App\Models\SocialLink; // Import SocialLink
use App\Models\Category; // Import Category
use App\Models\Announcement;
use App\Models\Application;

class User extends Authenticatable implements MustVerifyEmail
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'email',
        'password',
        'type',
        'onboarding_completed_at',
        'profile_verified_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'onboarding_completed_at' => 'datetime',
            'profile_verified_at' => 'datetime',
            'password' => 'hashed',
            'type' => UserType::class,
        ];
    }

    public function brandProfile()
    {
        return $this->hasOne(BrandProfile::class);
    }

    public function creatorProfile()
    {
        return $this->hasOne(CreatorProfile::class);
    }

    public function socialLinks()
    {
        return $this->hasMany(SocialLink::class);
    }

    public function categories()
    {
        return $this->belongsToMany(Category::class, 'user_categories');
    }

    public function sendEmailVerificationNotification()
    {
        $this->notify(new \App\Notifications\Auth\QueuedVerifyEmail);
    }

    public function isBrand(): bool
    {
        return $this->type === UserType::BRAND;
    }

    public function isCreator(): bool
    {
        return $this->type === UserType::CREATOR;
    }

    public function announcements()
    {
        return $this->hasMany(Announcement::class);
    }

    public function applications()
    {
        return $this->hasMany(Application::class);
    }
}

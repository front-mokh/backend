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
        'expo_push_token',
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

    /**
     * Get a display name from brand or creator profile.
     */
    public function getDisplayNameAttribute(): string
    {
        if ($this->isBrand() && $this->brandProfile) {
            return $this->brandProfile->name;
        }
        if ($this->isCreator() && $this->creatorProfile) {
            return $this->creatorProfile->nickname ?? ($this->creatorProfile->first_name . ' ' . $this->creatorProfile->last_name);
        }
        return $this->email;
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

    public function collaborationsAsBrand()
    {
        return $this->hasMany(Collaboration::class, 'brand_id');
    }

    public function collaborationsAsCreator()
    {
        return $this->hasMany(Collaboration::class, 'creator_id');
    }

    public function messages()
    {
        return $this->hasMany(Message::class, 'sender_id');
    }
}

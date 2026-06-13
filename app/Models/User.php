<?php

namespace App\Models;

use App\Enums\UserType;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

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
        'expo_push_token',
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
            return $this->creatorProfile->nickname ?? ($this->creatorProfile->first_name.' '.$this->creatorProfile->last_name);
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

    public function reviewsGiven()
    {
        return $this->hasMany(CollaborationReview::class, 'reviewer_id');
    }

    public function reviewsReceived()
    {
        return $this->hasMany(CollaborationReview::class, 'reviewed_user_id');
    }

    public function reputationSummary(): array
    {
        $publishedReviews = $this->reviewsReceived()->published();
        $reviewsCount = (clone $publishedReviews)->count();
        $averageRating = $reviewsCount > 0
            ? round((float) (clone $publishedReviews)->avg('rating'), 1)
            : null;

        $wouldWorkAgainCount = (clone $publishedReviews)
            ->where('would_work_again', true)
            ->count();

        $completedCollaborationsCount = $this->isCreator()
            ? $this->collaborationsAsCreator()->where('status', 'completed')->count()
            : $this->collaborationsAsBrand()->where('status', 'completed')->count();

        $ratingScore = $averageRating === null ? 0 : ($averageRating / 5) * 70;
        $completionScore = (min($completedCollaborationsCount, 10) / 10) * 20;
        $repeatScore = $reviewsCount === 0 ? 0 : ($wouldWorkAgainCount / $reviewsCount) * 10;

        return [
            'average_rating' => $averageRating,
            'reviews_count' => $reviewsCount,
            'completed_collaborations_count' => $completedCollaborationsCount,
            'would_work_again_rate' => $reviewsCount === 0
                ? null
                : (int) round(($wouldWorkAgainCount / $reviewsCount) * 100),
            'reliability_score' => (int) round($ratingScore + $completionScore + $repeatScore),
            'rating_breakdown' => [
                'communication' => $this->averageReviewMetric('communication_rating'),
                'quality' => $this->averageReviewMetric('quality_rating'),
                'reliability' => $this->averageReviewMetric('reliability_rating'),
                'professionalism' => $this->averageReviewMetric('professionalism_rating'),
            ],
        ];
    }

    private function averageReviewMetric(string $column): ?float
    {
        $average = $this->reviewsReceived()
            ->published()
            ->whereNotNull($column)
            ->avg($column);

        return $average === null ? null : round((float) $average, 1);
    }

    public function messages()
    {
        return $this->hasMany(Message::class, 'sender_id');
    }

    public function pushDeviceTokens()
    {
        return $this->hasMany(PushDeviceToken::class);
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CollaborationReview extends Model
{
    protected $fillable = [
        'collaboration_id',
        'reviewer_id',
        'reviewed_user_id',
        'reviewer_role',
        'rating',
        'communication_rating',
        'quality_rating',
        'reliability_rating',
        'professionalism_rating',
        'would_work_again',
        'public_comment',
        'status',
    ];

    protected $casts = [
        'rating' => 'integer',
        'communication_rating' => 'integer',
        'quality_rating' => 'integer',
        'reliability_rating' => 'integer',
        'professionalism_rating' => 'integer',
        'would_work_again' => 'boolean',
    ];

    public function collaboration()
    {
        return $this->belongsTo(Collaboration::class);
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewer_id');
    }

    public function reviewedUser()
    {
        return $this->belongsTo(User::class, 'reviewed_user_id');
    }

    public function scopePublished($query)
    {
        return $query->where('status', 'published');
    }
}

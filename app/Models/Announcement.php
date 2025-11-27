<?php

namespace App\Models;

use App\Enums\ProjectStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Announcement extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'category_id',
        'title',
        'description',
        'budget_min',
        'budget_max',
        'deadline',
        'delivery_date',
        'duration',
        'target_audience',
        'requirements',
        'min_followers',
        'influencer_tier_id',
        'thumbnail',
        'attachment',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'deadline' => 'date',
            'delivery_date' => 'date',
        ];
    }

    public function getThumbnailAttribute($value)
    {
        return $value ? asset('storage/' . $value) : null;
    }

    public function getAttachmentAttribute($value)
    {
        return $value ? asset('storage/' . $value) : null;
    }


    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function applications()
    {
        return $this->hasMany(Application::class);
    }

    public function platforms()
    {
        return $this->belongsToMany(Platform::class, 'announcement_platform');
    }

    public function deliverables()
    {
        return $this->belongsToMany(DeliverableType::class, 'announcement_deliverable')
                    ->withPivot('quantity');
    }

    public function influencerTier()
    {
        return $this->belongsTo(InfluencerTier::class);
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Collaboration extends Model
{
    protected $fillable = [
        'application_id',
        'announcement_id',
        'brand_id',
        'creator_id',
        'status',
        'started_at',
        'completed_at',
        'brand_last_seen_at',
        'creator_last_seen_at',
        'brand_last_read_at',
        'creator_last_read_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
        'brand_last_seen_at' => 'datetime',
        'creator_last_seen_at' => 'datetime',
        'brand_last_read_at' => 'datetime',
        'creator_last_read_at' => 'datetime',
    ];

    /**
     * Check if a user is currently viewing this collaboration chat.
     * Returns true if the user's last_seen_at is within the threshold.
     */
    public function isUserViewing(User $user, int $thresholdSeconds = 30): bool
    {
        $lastSeen = $user->id === $this->brand_id
            ? $this->brand_last_seen_at
            : $this->creator_last_seen_at;

        if (!$lastSeen) {
            return false;
        }

        return $lastSeen->diffInSeconds(now()) <= $thresholdSeconds;
    }

    /**
     * Count unread messages for a given user in this collaboration.
     * Messages sent by others after the user's last_read_at.
     */
    public function unreadCountFor(User $user): int
    {
        $lastReadAt = $user->id === $this->brand_id
            ? $this->brand_last_read_at
            : $this->creator_last_read_at;

        $query = $this->messages()
            ->where('sender_id', '!=', $user->id);

        if ($lastReadAt) {
            $query->where('created_at', '>', $lastReadAt);
        }

        return $query->count();
    }

    public function application()
    {
        return $this->belongsTo(Application::class);
    }

    public function announcement()
    {
        return $this->belongsTo(Announcement::class);
    }

    public function brand()
    {
        return $this->belongsTo(User::class, 'brand_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'creator_id');
    }

    public function messages()
    {
        return $this->hasMany(Message::class);
    }

    public function submissions()
    {
        return $this->hasMany(DeliverableSubmission::class);
    }
}

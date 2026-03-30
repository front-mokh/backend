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
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

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

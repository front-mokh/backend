<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppNotification extends Model
{
    protected $fillable = [
        'user_id',
        'type',
        'title',
        'body',
        'data',
        'read_at',
    ];

    protected function casts(): array
    {
        return [
            'data' => 'array',
            'read_at' => 'datetime',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function scopeUnread($query)
    {
        return $query->whereNull('read_at');
    }
}

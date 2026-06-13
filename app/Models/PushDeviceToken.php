<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PushDeviceToken extends Model
{
    protected $fillable = [
        'user_id',
        'provider',
        'platform',
        'device_id',
        'app_version',
        'token_hash',
        'token',
        'last_used_at',
    ];

    protected $hidden = [
        'token',
        'token_hash',
    ];

    protected function casts(): array
    {
        return [
            'last_used_at' => 'datetime',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public static function hashToken(string $token): string
    {
        return hash('sha256', $token);
    }
}

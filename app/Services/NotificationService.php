<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    /**
     * Send a notification to a user (DB + Push)
     */
    public static function send(
        User $user,
        string $type,
        string $title,
        string $body,
        array $data = []
    ): AppNotification {
        // 1. Create DB notification
        $notification = AppNotification::create([
            'user_id' => $user->id,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'data' => $data,
        ]);

        // 2. Send Expo Push Notification (if token exists)
        if ($user->expo_push_token) {
            static::sendExpoPush($user->expo_push_token, $title, $body, $data);
        }

        // 3. Broadcast real-time event to connected WebSockets
        broadcast(new \App\Events\NewNotificationEvent($notification))->toOthers();

        return $notification;
    }

    /**
     * Send push notification via Expo Push API
     */
    protected static function sendExpoPush(
        string $token,
        string $title,
        string $body,
        array $data = []
    ): void {
        try {
            Http::post('https://exp.host/--/api/v2/push/send', [
                'to' => $token,
                'title' => $title,
                'body' => $body,
                'data' => $data,
                'sound' => 'default',
                'priority' => 'high',
                'channelId' => 'default',
            ]);
        } catch (\Exception $e) {
            Log::error('Expo push notification failed: ' . $e->getMessage());
        }
    }

    /**
     * Send a push-only notification (no DB record).
     * Used for chat messages — they should buzz the phone but NOT
     * appear in the notification list (like WhatsApp/Telegram).
     */
    public static function sendPushOnly(
        User $user,
        string $title,
        string $body,
        array $data = []
    ): void {
        // Send Expo Push Notification (if token exists)
        if ($user->expo_push_token) {
            static::sendExpoPush($user->expo_push_token, $title, $body, $data);
        }
    }

    /**
     * Send to multiple users at once
     */
    public static function sendToMany(
        array $users,
        string $type,
        string $title,
        string $body,
        array $data = []
    ): void {
        foreach ($users as $user) {
            static::send($user, $type, $title, $body, $data);
        }
    }
}

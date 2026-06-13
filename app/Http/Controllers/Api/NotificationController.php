<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\PushDeviceToken;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NotificationController extends Controller
{
    /**
     * List user's notifications (latest first)
     */
    public function index(Request $request)
    {
        $notifications = AppNotification::where('user_id', $request->user()->id)
            ->latest()
            ->paginate(30);

        return response()->json($notifications);
    }

    /**
     * Get unread notification count
     */
    public function unreadCount(Request $request)
    {
        $count = AppNotification::where('user_id', $request->user()->id)
            ->unread()
            ->count();

        return response()->json(['count' => $count]);
    }

    /**
     * Mark a single notification as read
     */
    public function markAsRead(Request $request, AppNotification $notification)
    {
        if ($notification->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $notification->update(['read_at' => now()]);

        return response()->json($notification);
    }

    /**
     * Mark all notifications as read
     */
    public function markAllAsRead(Request $request)
    {
        AppNotification::where('user_id', $request->user()->id)
            ->unread()
            ->update(['read_at' => now()]);

        return response()->json(['message' => 'All notifications marked as read']);
    }

    public function storeDeviceToken(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string|max:4096',
            'provider' => ['nullable', Rule::in(['fcm', 'expo'])],
            'platform' => ['nullable', Rule::in(['android', 'ios', 'web', 'macos', 'windows', 'linux', 'unknown'])],
            'device_id' => 'nullable|string|max:255',
            'app_version' => 'nullable|string|max:50',
        ]);

        $deviceToken = $this->upsertDeviceToken(
            $request,
            $validated['provider'] ?? 'fcm',
            $validated
        );

        return response()->json([
            'message' => 'Push token registered',
            'device_token' => [
                'id' => $deviceToken->id,
                'provider' => $deviceToken->provider,
                'platform' => $deviceToken->platform,
                'last_used_at' => $deviceToken->last_used_at,
            ],
        ], $deviceToken->wasRecentlyCreated ? 201 : 200);
    }

    public function destroyDeviceToken(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string|max:4096',
        ]);

        $deleted = $request->user()
            ->pushDeviceTokens()
            ->where('token_hash', PushDeviceToken::hashToken($validated['token']))
            ->delete();

        return response()->json([
            'message' => 'Push token removed',
            'deleted' => $deleted > 0,
        ]);
    }

    /**
     * Store/update the user's Expo Push Token for legacy clients.
     */
    public function storePushToken(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string|max:4096',
            'platform' => ['nullable', Rule::in(['android', 'ios', 'web', 'macos', 'windows', 'linux', 'unknown'])],
            'device_id' => 'nullable|string|max:255',
            'app_version' => 'nullable|string|max:50',
        ]);

        $this->upsertDeviceToken($request, 'expo', $validated);
        $request->user()->update(['expo_push_token' => $validated['token']]);

        return response()->json(['message' => 'Push token registered']);
    }

    private function upsertDeviceToken(Request $request, string $provider, array $validated): PushDeviceToken
    {
        return PushDeviceToken::updateOrCreate(
            ['token_hash' => PushDeviceToken::hashToken($validated['token'])],
            [
                'user_id' => $request->user()->id,
                'provider' => $provider,
                'platform' => $validated['platform'] ?? null,
                'device_id' => $validated['device_id'] ?? null,
                'app_version' => $validated['app_version'] ?? null,
                'token' => $validated['token'],
                'last_used_at' => now(),
            ]
        );
    }

    /**
     * Delete a single notification
     */
    public function destroy(Request $request, AppNotification $notification)
    {
        if ($notification->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $notification->delete();

        return response()->json(['message' => 'Notification deleted']);
    }

    /**
     * Delete all notifications for the user
     */
    public function destroyAll(Request $request)
    {
        AppNotification::where('user_id', $request->user()->id)->delete();

        return response()->json(['message' => 'All notifications deleted']);
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\Request;

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

    /**
     * Store/update the user's Expo Push Token
     */
    public function storePushToken(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string',
        ]);

        $request->user()->update(['expo_push_token' => $validated['token']]);

        return response()->json(['message' => 'Push token registered']);
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

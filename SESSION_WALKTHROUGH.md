# Session Walkthrough — April 4, 2026

## Overview
This session redesigned the messaging notification system to match state-of-the-art messaging apps (WhatsApp/Telegram). Messages no longer pollute the notification list — they use push-only alerts with presence detection and throttling.

---

## 1. Smart Messaging Notifications

### Problem
Every message in a collaboration triggered the full notification pipeline:
- DB record in `app_notifications` → polluted the notification list
- Expo push notification → buzzed the phone on every message
- WebSocket broadcast (`NewNotificationEvent`) → redundant since `NewMessageEvent` already handles real-time delivery

20 messages = 20 push notifications + 20 notification list entries.

### Solution: Two-Layer Smart Notifications

| Scenario | Result |
|----------|--------|
| Recipient is **viewing the chat** (last_seen < 30s) | ❌ No push (WebSocket handles it) |
| Recipient is **away**, no recent push | ✅ Push-only (no DB record) |
| Recipient is **away**, push sent < 2 min ago | ❌ Skip (throttled) |

### Backend Changes

#### Migration: `2026_04_04_221800_add_read_tracking_to_collaborations`
Added 4 columns to `collaborations`:
- `brand_last_seen_at` / `creator_last_seen_at` — presence detection
- `brand_last_read_at` / `creator_last_read_at` — unread message tracking

#### [Collaboration.php](file:///home/tokita/Documents/GitHub/backend_mob/app/Models/Collaboration.php)
- `isUserViewing(User $user)` — returns `true` if user's `last_seen_at` < 30 seconds ago
- `unreadCountFor(User $user)` — counts messages after user's `last_read_at`

#### [NotificationService.php](file:///home/tokita/Documents/GitHub/backend_mob/app/Services/NotificationService.php)
- `sendPushOnly()` — sends Expo push **without** creating a DB record

#### [CollaborationController.php](file:///home/tokita/Documents/GitHub/backend_mob/app/Http/Controllers/Api/CollaborationController.php)
- `show()` — updates `last_seen_at` + `last_read_at` when user opens chat
- `sendMessage()` — presence check → throttle check → push-only (no DB record)
- `heartbeat()` — **NEW** — refreshes `last_seen_at` (mobile calls every ~15s)
- `markAsRead()` — **NEW** — updates `last_read_at`
- `index()` — now appends `unread_count` per collaboration

#### [routes/api.php](file:///home/tokita/Documents/GitHub/backend_mob/routes/api.php)
```
POST /collaborations/{id}/heartbeat   → CollaborationController::heartbeat
POST /collaborations/{id}/read        → CollaborationController::markAsRead
```

### Mobile Changes

#### [api.ts](file:///home/tokita/Documents/GitHub/backend_mob/react_native_app/mobile/lib/api.ts)
- `Collaboration` interface now includes `unread_count?: number`
- New methods: `sendHeartbeat(id)`, `markCollabAsRead(id)`

---

## Startup Commands

```bash
# Laravel Backend
php artisan serve --host=0.0.0.0 --port=8001

# React Native (Expo)
EXPO_OFFLINE=1 REACT_NATIVE_PACKAGER_HOSTNAME=10.139.115.90 npx expo start --clear
```

> ⚠️ Use `EXPO_OFFLINE=1` to skip Expo's network version checks (unstable internet).
> ⚠️ If IP changes, update `react_native_app/mobile/.env` → `EXPO_PUBLIC_API_URL`.

---

## Remaining TODO
- [ ] **Mobile: Integrate heartbeat** — Chat screen needs `setInterval` calling `api.sendHeartbeat(id)` every ~15s
- [ ] **Mobile: Unread badges** — Use `unread_count` from collaborations list to show badges on collaboration cards/tab
- [ ] Implement Forgot Password / Reset Password API
- [ ] Implement Basic Search Filters for Campaigns
- [ ] Implement Admin Moderation Logic (Pending → Published)
- [ ] Implement Authentication screens and storage improvements
- [ ] Implement Creator/Brand Onboarding screen refinements
- [ ] Fix `"fezfzef"` invalid Ionicon warnings (some icon names in DB are invalid)
- [ ] Fix `Text strings must be rendered within <Text>` error in creator profile social links section

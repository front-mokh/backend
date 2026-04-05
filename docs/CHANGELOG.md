# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/) and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added — April 2026
- **Smart messaging notifications** — Two-layer system: presence detection (skip push when recipient is in chat) + cache-based throttling (1 push per collab per 2 min)
- **Push-only message alerts** — `NotificationService::sendPushOnly()` sends Expo push without creating DB notification records (messages ≠ notifications)
- **Presence tracking** — `brand_last_seen_at` / `creator_last_seen_at` columns on `collaborations` table; `Collaboration::isUserViewing()` helper
- **Unread message tracking** — `brand_last_read_at` / `creator_last_read_at` columns; `Collaboration::unreadCountFor()` helper
- **Heartbeat endpoint** — `POST /collaborations/{id}/heartbeat` to refresh presence while user stays in chat
- **Mark as read endpoint** — `POST /collaborations/{id}/read` to update last_read_at
- **Unread counts in collab list** — `GET /collaborations` now returns `unread_count` per collaboration
- **Collaborations system** — Workspace created on application acceptance, with messaging, deliverable submissions, and status tracking
- **In-app notifications** — `AppNotification` model + `NotificationController` for list, unread count, mark read
- **Expo push notifications** — `NotificationService` sends push via Expo API + stores push tokens
- **WebSocket events** — `NewMessageEvent` and `NewNotificationEvent` for real-time updates via Laravel Reverb
- **Platform-grouped deliverables** — `DeliverableType` now has `platform_id`, grouped UI in mobile app
- **Collaborations page** — Rebuilt with ScreenLayout, search, and filter chips for both brand and creator views

### Fixed — April 2026
- **Android nav bar overlap** — Used `useSafeAreaInsets()` for dynamic bottom padding in tab layouts
- **Routing bugs** — Fixed broken post-onboarding and post-apply redirects for brand/creator flows
- **API data loading** — Added `brandProfile.industries` and `categories` to `/user` eager loading
- **Social link crash** — Added null guard in `getSocialIcon` and `getSocialPlatformName`
- **Candidature details** — Fixed `getSocialIcon(link.platform)` → `getSocialIcon(link.url)`

### Changed — April 2026
- **Premium UI redesign** — Deeper violet palette, gold accent, shadow/elevation on cards and buttons
- **Tab bar** — Deep violet background with upward shadow and bold labels

---

### Added — November 2025
- **Authentication** — Signup, login, logout endpoints with Sanctum token auth
- **Email verification** — Queued `QueuedVerifyEmail` notification for async processing
- **Onboarding** — Separate flows for brands (name + industries) and creators (profile + categories + social links)
- **Categories** — `Category` model, `user_categories` pivot table, `GET /api/categories` endpoint
- **Industries** — `Industry` model, `brand_profile_industry` pivot table, `GET /api/industries` endpoint
- **Social links** — Refactored from hardcoded columns to dedicated `social_links` table
- **Nickname** — Added optional `nickname` field to `creator_profiles`
- **Announcements** — Full CRUD with authorization policy, platform/deliverable associations
- **Applications** — Apply to announcements, accept/reject flow
- **Platforms & Deliverables** — Reference data endpoints
- **Influencer tiers** — Reference data endpoint
- **Admin panel** — Filament v3 with resources for users, announcements, categories, platforms, deliverables
- **Admin model** — Separate `Admin` model with dedicated guard for Filament access

# Project Knowledge Base

## Recent Changes Log
### [2026-04-04] Smart Messaging Notifications
- **Status**: IMPLEMENTED
- **Description**: Redesigned the messaging notification system to match state-of-the-art messaging apps (WhatsApp/Telegram). Messages no longer create entries in the notification list — the notification center is now reserved for platform events only (candidatures, deliverables). Push notifications for messages are throttled and presence-aware.
- **Architecture — Two-Layer Smart Notifications**:
    - **Layer 1 — Presence Detection**: Tracks `brand_last_seen_at` / `creator_last_seen_at` on each collaboration. If the recipient was seen in the last 30 seconds, notifications are skipped entirely (WebSocket delivers the message in real-time).
    - **Layer 2 — Throttling**: When the recipient is away, only one push notification is sent per collaboration per 2-minute window (cache-based via `Cache::put()`).
    - **Push-Only**: Messages send Expo push alerts without creating `AppNotification` DB records. The `sendPushOnly()` method in `NotificationService` handles this.
- **Impact**:
    - `database/migrations/2026_04_04_221800_add_read_tracking_to_collaborations.php`: New migration — adds `brand_last_seen_at`, `creator_last_seen_at`, `brand_last_read_at`, `creator_last_read_at` to `collaborations`.
    - `app/Models/Collaboration.php`: Added `isUserViewing()` and `unreadCountFor()` helper methods.
    - `app/Services/NotificationService.php`: Added `sendPushOnly()` method (push without DB record).
    - `app/Http/Controllers/Api/CollaborationController.php`: Rewrote `sendMessage()` with 2-layer smart notifications; added `heartbeat()`, `markAsRead()`; `index()` now returns `unread_count`.
    - `routes/api.php`: Added `POST /collaborations/{id}/heartbeat` and `POST /collaborations/{id}/read`.
    - `react_native_app/mobile/lib/api.ts`: Added `unread_count` to `Collaboration` interface; added `sendHeartbeat()` and `markCollabAsRead()` API methods.
- **TODO — Mobile Integration**:
    - The mobile chat screen needs to call `api.sendHeartbeat(id)` every ~15 seconds via `setInterval` while the chat is open.
    - Use `unread_count` from the collaborations list endpoint to show unread badges on the collaborations tab.
- **Testing**:
    - Migration ran successfully (batch 4).
    - All 21 existing tests passed with 0 failures.

### [2025-11-21] Create Categories Endpoint
- **Status**: IMPLEMENTING
- **Description**: Created a new API endpoint to retrieve all categories with their `id`, `name`, and `description`.
- **Impact**:
    - `app/Http/Controllers/Api/CategoryController.php`: New controller created.
    - `routes/api.php`: New GET route `/api/categories` added.
- **Implementation**:
    - Created `Api\CategoryController`.
    - Implemented the `index` method in `Api\CategoryController` to fetch all categories and return them as a JSON response.
    - Added `Route::get('/categories', [CategoryController::class, 'index']);` to `routes/api.php`.
- **Testing**:
    - Manual testing by accessing the `/api/categories` endpoint to verify that a JSON array of categories (with `id`, `name`, `description`) is returned.

### [2025-11-21] Update Creator Onboarding Endpoint
- **Status**: IMPLEMENTING
- **Description**: Modified the `storeCreatorProfile` method in `OnboardingController` to match the new schema for social links and categories, including validation and French error messages.
- **Impact**:
    - `app/Http/Controllers/Onboarding/OnboardingController.php`: Updated the `storeCreatorProfile` method.
- **Implementation**:
    - Removed old social media handle fields from validation and `CreatorProfile` creation.
    - Added new validation rules for `links` (array of URLs, min 1, max 6) and `categories` (array of existing category IDs, min 1, max 3).
    - Integrated French error messages for all validation rules in `storeCreatorProfile` and `storeBrandProfile`.
    - Modified `CreatorProfile::create` to use the new `nickname` field.
    - Added logic to store `SocialLink` records associated with the user.
    - Added logic to attach `Category` records to the user.
- **Testing**:
    - Functional testing of the `/api/onboarding/creator` endpoint with valid and invalid data for links, categories, and other profile fields.
    - Verify that French error messages are returned for invalid inputs.

### [2025-11-21] Add Nickname to Creator Profile
- **Status**: IMPLEMENTING
- **Description**: Added an optional `nickname` field to the `creator_profiles` table and model.
- **Impact**:
    - `database/migrations/2025_10_31_152641_create_creator_profiles_table.php`: Modified to include a `nickname` column.
    - `app/Models/CreatorProfile.php`: Modified to include `nickname` in the `$fillable` property and removed the deprecated `instagram_handle` and `tiktok_handle` from `$fillable`.
- **Implementation**:
    - Added `nickname` column (`string`, nullable) to the `creator_profiles` table.
    - Updated `CreatorProfile` model's `$fillable` array.
- **Testing**:
    - Manual verification after running `php artisan migrate:refresh` to ensure the column is added correctly and the model can access it.
    - Future: Create unit/feature tests for CreatorProfile nickname management.

### [2025-11-21] Add User Categories
- **Status**: IMPLEMENTING
- **Description**: Added a new `Category` model and a many-to-many relationship between `Users` and `Categories` to track user interests or work areas.
- **Impact**:
    - `app/Models/Category.php`: New model created for categories.
    - `app/Models/User.php`: Modified to include a `belongsToMany` relationship for `categories()`.
    - `database/migrations/2025_11_21_165518_create_categories_table.php`: New migration created to establish the `categories` table.
    - `database/migrations/2025_11_21_165544_create_user_categories_table.php`: New migration created to establish the `user_categories` pivot table.
- **Implementation**:
    - Created `Category` model with `$fillable` properties for `name` and `description`.
    - Created `categories` table with `id`, `name` (unique), `description`, and timestamps.
    - Created `user_categories` pivot table with `id`, `user_id`, `category_id`, and a unique constraint on the combination of `user_id` and `category_id`.
    - Added `belongsToMany` relationships in both `User` and `Category` models for `categories()` and `users()` respectively.
- **Testing**:
    - Manual verification after running `php artisan migrate` to ensure the tables are created correctly and relationships are established.
    - Future: Create unit/feature tests for Category creation, retrieval, and association with users.

### [2025-11-21] Refactor Social Media Links
- **Status**: IMPLEMENTING
- **Description**: Refactored the storage of social media links from hardcoded columns in `creator_profiles` to a dedicated `social_links` table linked to the `users` table.
- **Impact**:
    - `database/migrations/2025_10_31_152641_create_creator_profiles_table.php`: Modified to remove `instagram_handle` and `tiktok_handle` columns.
    - `database/migrations/2025_11_21_163843_create_social_links_table.php`: Modified to create a `social_links` table with `user_id` (foreign key to users), `url`, and `is_verified` (boolean, default false). The previous pivot table creation was removed.
    - `app/Models/SocialLink.php`: Modified to include `user_id` and `is_verified` in `$fillable` and define the `user()` relationship.
    - `app/Models/User.php`: Modified to include a `hasMany` relationship for `socialLinks()`.
    - `app/Models/CreatorProfile.php`: No direct changes, but its associated data structure has changed.
    - `app/Models/BrandProfile.php`: No direct changes, but its associated data structure has changed.
- **Implementation**:
    - Removed `instagram_handle` and `tiktok_handle` columns from `creator_profiles` table definition.
    - Created `social_links` table with `id`, `user_id`, `url`, `is_verified` (default false), and timestamps. `user_id` is a foreign key to the `users` table. A unique constraint was added on `user_id` and `url`.
    - Updated `SocialLink` model to reflect the new table structure and relationships.
    - Updated `User` model to establish a `hasMany` relationship with `SocialLink`.
- **Testing**:
    - Manual verification after running `php artisan migrate:refresh` (as requested by the user) to ensure the tables are created correctly and relationships are established.
    - Future: Create unit/feature tests for SocialLink creation, retrieval, and association with users.

### [2025-11-21] Signup Controller Optimization & Logout Functionality
- **Status**: IMPLEMENTED
- **Description**: Optimized the signup process by queuing email verification notifications and added a new API endpoint for user logout.
- **Impact**:
    - `app/Http/Controllers/Auth/SignupController.php`: Reduced execution time by making email verification asynchronous.
    - `app/Models/User.php`: Modified to use a queued email verification notification.
    - `app/Notifications/Auth/QueuedVerifyEmail.php`: New file created for the queued email verification notification.
    - `app/Http/Controllers/Auth/LoginController.php`: Added a `logout` method to revoke user access tokens.
    - `routes/api.php`: Added a new POST route `/api/logout` for user logout.
- **Implementation**:
    - **Signup Optimization**:
        1. Created `app/Notifications/Auth/QueuedVerifyEmail.php` which extends `Illuminate\Auth\Notifications\VerifyEmail` and implements `Illuminate\Contracts\Queue\ShouldQueue`. This ensures email verification is pushed to the queue for background processing.
        2. Overrode the `sendEmailVerificationNotification()` method in `app/Models/User.php` to use the new `QueuedVerifyEmail` notification. This change ensures that when the `Registered` event is fired during signup, the email verification notification is queued instead of being sent synchronously.
    - **Logout Functionality**:
        1. Added a `logout` method to `app/Http/Controllers/Auth/LoginController.php`. This method uses `currentAccessToken()->delete()` to revoke the current user's personal access token, effectively logging them out.
        2. Added a new route `Route::post('/logout', [LoginController::class, 'logout'])->middleware('auth:sanctum');` to `routes/api.php` to expose the logout functionality.
- **Testing**:
    - **Signup Optimization**: Verified by running `tests/Feature/Auth/SignupTest.php` after temporarily adding a test case that used `Notification::fake()` and `Notification::assertSentTo()` to confirm that `App\Notifications\Auth\QueuedVerifyEmail` was dispatched. All existing tests passed, and the added test confirmed the notification was sent.
    - **Logout Functionality**: Verified by running `tests/Feature/Auth/LoginTest.php` after temporarily adding a test case that logged in a user, called the logout endpoint, and then asserted a successful logout (HTTP 200) and token invalidation (checked `assertDatabaseMissing`).
    - **Queue Worker**: To process queued emails, a queue worker must be running (e.g., `php artisan queue:work`).

## Architecture Overview
- **Monorepo** — Laravel backend + React Native mobile app in `react_native_app/mobile/`
- **API-first** — All client communication via JSON REST endpoints (`routes/api.php`)
- **Token auth** — Laravel Sanctum personal access tokens, no sessions for API
- **Real-time** — Laravel Reverb WebSocket server for message and notification broadcasting
- **Admin** — Filament v3 panel at `/admin` with a separate `Admin` model and guard
- **Notification pipeline** — Platform events (candidatures, deliverables): `NotificationService::send()` writes to `app_notifications` DB → Expo push → WebSocket broadcast. Chat messages: `NotificationService::sendPushOnly()` sends Expo push only (no DB record), with presence detection + 2-min throttle.

## Component Inventory
| Component | Responsibility |
|-----------|---------------|
| `Auth\SignupController` | User registration + queued email verification |
| `Auth\LoginController` | Token issuance + logout (token revocation) |
| `Onboarding\OnboardingController` | Brand & Creator profile creation + social links + categories |
| `Api\AnnouncementController` | Campaign CRUD + close with authorization policies |
| `Api\ApplicationController` | Apply to campaigns, accept/reject with collaboration creation |
| `Api\CollaborationController` | Workspace: messaging, deliverable submissions, status updates |
| `Api\NotificationController` | List, unread count, mark read, Expo push token registration |
| `Services\NotificationService` | Unified service: DB notification + Expo push + WebSocket broadcast |
| `Events\NewMessageEvent` | WebSocket broadcast for real-time messaging |
| `Events\NewNotificationEvent` | WebSocket broadcast for real-time notifications |
| `Policies\AnnouncementPolicy` | Authorization for announcement update/delete |

## Configuration Map
| File | Purpose |
|------|---------|
| `.env` | Environment variables (DB, Mail, Reverb, App key) |
| `config/sanctum.php` | Sanctum token/guard config |
| `config/reverb.php` | WebSocket server config |
| `config/broadcasting.php` | Broadcast driver (reverb) |
| `config/filament.php` | Admin panel configuration |
| `routes/api.php` | All API route definitions |
| `routes/channels.php` | WebSocket channel authorization |

## Data Flow & Integration Points
1. **Auth flow**: Mobile → `POST /api/signup` → User created → Queued email verification → `POST /api/login` → Sanctum token returned
2. **Campaign flow**: Brand creates announcement → Creators browse/filter → Creator applies → Brand accepts → Collaboration workspace created
3. **Collaboration flow**: Messages via REST + WebSocket broadcast → Creator submits deliverables → Brand approves/rejects → Status updated to completed
4. **Notification flow**: Controller action → `NotificationService::send()` → DB record + Expo push (if token) + WebSocket broadcast

## Testing Strategy
- **Framework**: PHPUnit 11.5
- **Existing tests**: Auth tests (`SignupTest`, `LoginTest`, `EmailVerificationTest`), Onboarding tests (`OnboardingFlowTest`, `OnboardingTest`), and `UserJourneyTest` (full signup → verify → login → onboard integration test)
- **Test pattern**: Feature tests with `RefreshDatabase` trait, `Notification::fake()` for email assertions
- **Run**: `php artisan test`

## Development Patterns
- **Enums**: `UserType`, `ProjectStatus`, `ApplicationStatus` backed enums for type safety
- **Relationships**: Consistent Eloquent relationships with eager loading (e.g., `with()`, `load()`)
- **Authorization**: Gate/Policy checks in controllers (e.g., `Gate::authorize('update', $announcement)`)
- **Validation**: Inline validation rules with French error messages for user-facing endpoints
- **File uploads**: Stored via `store()` to public disk (`announcements/`, `messages/`, `submissions/`)
- **Message notifications**: Push-only (no DB record), throttled (1 per collab per 2 min), presence-aware (skipped if recipient is viewing chat). Uses `Cache` for throttle keys (`msg_push:{user_id}:{collab_id}`).
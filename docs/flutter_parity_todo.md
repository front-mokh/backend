# Flutter Parity Todo

## Project Components

- Backend: Laravel API in `app/Http/Controllers/Api`, domain models in `app/Models`, notifications in `app/Notifications` and `app/Services`, realtime events in `app/Events`, API routes in `routes/api.php`.
- Database: migrations, factories, and seeders in `database`; demo accounts are seeded through `database/seeders/DemoDataSeeder.php`.
- React Native reference app: `react_native_app/mobile`; this remains the feature baseline for parity.
- Flutter app: `flutter_app`; main product code is in `lib/core` for shared services/models/routing/theme and `lib/features` for auth, onboarding, brand, creator, and shared screens.
- Tests: Laravel tests in `tests`; Flutter widget tests in `flutter_app/test`.

## Completed In Current Pass

- Added backend `POST /collaborations/{collaboration}/complete` controller handling so Flutter can complete collaborations through the existing API route.
- Locked announcement creation to brand users on the backend.
- Fixed Flutter model parsing for backend social links and deliverable submission relationship names.
- Replaced Flutter realtime setup with a Reverb-compatible websocket client using Pusher protocol private-channel auth.
- Added collaboration chat realtime handling, read tracking, heartbeat presence, and file attachments for brand and creator detail screens.
- Fixed brand deliverable approval visibility for backend `submitted` status.
- Added notification tap navigation from backend routes to Flutter routes and optimistic read-state updates.
- Added unread notification badges and profile bottom tabs to both brand and creator shells.
- Added social link display to brand and creator profiles.
- Replaced the default Flutter counter test with an app smoke test.
- Cleaned Flutter analyzer warnings so `flutter analyze` is green.
- Added realtime chat read receipts with visible `Envoyé` / `Vu` states.
- Added realtime unread badge updates in brand and creator collaboration lists.
- Added websocket reconnect/backoff and stream-based message/read-receipt handling.
- Added backend chat read-tracking tests.
- Fixed brand announcement list refresh after a successful announcement publish.
- Removed duplicate profile app bars and refreshed brand/creator profile data when profile tabs open.
- Added profile pull-to-refresh and explicit fallback values for missing phone/location fields.
- Fixed creator/brand onboarding completion state so successful final submits do not route users back to the first profile step.
- Audited Flutter pages for placeholders and incomplete parity.
- Added backend `GET /api/creators` for brand-side creator discovery and `GET /api/applications/{application}` for single application details.
- Added backend tests for creator discovery and application-detail authorization.
- Implemented Brand Creators discovery, Brand Edit Announcement, Creator Application Details, and fixed Brand Application Details.
- Added search/filter/count headers to brand announcements, creator announcements, creator applications, and brand/creator collaboration inboxes.
- Added collaboration details tabs, brand complete-collaboration action, and completed/cancelled locked states.
- Hardened Flutter model parsing so Laravel numeric IDs/counts are accepted as either integers or strings.
- Added required deliverables by platform to brand/creator candidature detail views and the creator collaboration deliverables tab.
- Fixed Android bottom safe-area spacing for the creator deliverable submit action and modal submit button.
- Added platform names to submitted deliverable titles and made candidature announcement cards open their announcement details.

## Missing Or Stubbed Flutter Pages

- None currently known in Priority 1.

## Implemented But Incomplete Compared To React Native

- Creator announcement discovery: search/category filters are implemented; budget, tier, and deadline filters still need advanced controls.
- Brand announcement management: search/status filters and application counts are implemented; explicit sorting is still pending.
- Brand-side application lists: status filtering inside announcement details can be improved.

## Priority 1: Core Product Parity

- Brand collaboration details:
  - [x] Add a dedicated details/summary tab with campaign, creator, budget, deadline, and current status.
  - [x] Add the visible "complete collaboration" action using `ApiService.completeCollaboration`.
  - [x] Confirm completed collaborations hide approval actions and show a final state.
- Creator collaboration details:
  - [x] Add a matching details/summary tab with campaign, brand, deadline, deliverables, and status.
  - [x] Make completed/cancelled states visually clear.
- Announcement discovery:
  - [x] Add creator search and category filters.
  - Add creator filters for budget, tier, and deadline.
  - Keep filter params aligned with `GET /api/announcements`.
- Brand announcement management:
  - [x] Add stronger list search/filter controls.
  - Add explicit sort controls.
  - [x] Surface pending/accepted/rejected application counts consistently.
  - Verify edit, close, delete, attachment, thumbnail, platforms, and deliverables match backend behavior.
- Missing page implementation:
  - [x] Build brand creator discovery/search instead of the current placeholder.
  - [x] Build brand edit announcement instead of the current placeholder.
  - [x] Build creator application details instead of the current placeholder.
- Applications:
  - Add richer brand-side application filtering by status.
  - [x] Add creator-side application status details and clearer navigation back to announcement/collaboration.

## Priority 2: Notifications And Realtime

- Manually test websocket reconnect/backoff and automatic private-channel resubscription on real Android/iOS devices.
- Continue migrating notification consumers from singleton callbacks to stream listeners where useful.
- Add "delete all notifications" if backend supports it, or add backend endpoint first.
- Add notification deep-link coverage for every backend notification route.
- Decide push strategy for Flutter:
  - Replace or extend Expo push token backend flow with Firebase Cloud Messaging for Flutter.
  - Add device token registration, refresh, logout cleanup, and push payload route mapping.

## Priority 3: UX And Mobile Polish

- Add loading, empty, and error states for every list screen.
- Add pull-to-refresh on list-heavy screens.
- Add pagination/infinite scrolling where backend responses support it.
- Standardize status labels and colors across announcements, applications, collaborations, and submissions.
- Improve attachment previews for PDF/video files.
- Add image/file size validation feedback before upload.
- Add offline/network failure messaging for API and websocket failures.

## Priority 4: Backend/API Hardening

- Add feature tests for:
  - Non-brand users cannot create announcements.
  - Brands can complete only their own collaborations.
  - Creators cannot complete collaborations.
  - Submission approval/rejection permissions.
  - Notification route payloads expected by mobile.
  - Chat send-message permissions and realtime read receipt payloads.
- Review policies for every collaboration and submission endpoint.
- Confirm uploaded files are exposed through stable public URLs consumed by mobile.
- Confirm Reverb channel names and broadcast event names are documented for app clients.

## Priority 5: Release Readiness

- Add Flutter integration tests for login, onboarding, announcement browsing, applying, chat, deliverable submission, and notification navigation.
- Add environment documentation for Flutter `.env`, backend API URL, Reverb host/port/key/scheme, and storage URL.
- Add build scripts/checklist for Android and iOS.
- Add CI steps for `php artisan test`, `flutter analyze`, and `flutter test`.
- Review app icons, splash screen, permissions, package IDs, and signing configuration.

## Current Verification

- Latest Flutter pass, 2026-06-13:
  - `flutter analyze`: passing with no issues.
  - `flutter test`: passing.
  - `flutter build apk --release`: passing.
- Backend unchanged in latest pass; last known `php artisan test`: passing, 31 tests / 100 assertions.

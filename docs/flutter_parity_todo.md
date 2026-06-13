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
- Standardized key backend response payloads for announcements, applications, collaborations, and submission status updates.
- Hid Expo push tokens from serialized user responses and added response-contract tests for mobile-critical payloads.
- Added shared Flutter loading, empty, error, and refreshable state widgets for primary list screens.
- Added visible retry/error handling and pull-to-refresh for empty/error states in brand announcements, creator announcements, creator applications, brand/creator collaborations, brand creator discovery, and notifications.
- Standardized Flutter status labels/colors for announcements, applications, collaborations, and deliverable submissions.
- Added richer attachment previews for images, PDFs, videos, and generic files in chat, announcement details, and deliverable details.
- Added pre-upload size validation for onboarding images, announcement thumbnails/PDFs, chat attachments, and deliverable submission attachments.
- Added user-visible realtime reconnection feedback in the brand and creator Flutter shells.
- Added robust no-cost Firebase Cloud Messaging push infrastructure for Flutter: backend device-token table, token registration/removal endpoints, FCM HTTP v1 sender, Flutter token sync, foreground notifications, tap route mapping, and Android notification permission/channel setup.
- Added cursor-paginated collaboration message history so Flutter opens chats on the latest messages and loads older messages only on request.

## Missing Or Stubbed Flutter Pages

- None currently known in Priority 1.

## Implemented But Still Needs Product Depth

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
  - [x] Replace or extend Expo push token backend flow with Firebase Cloud Messaging for Flutter.
  - [x] Add device token registration, refresh, logout cleanup, and push payload route mapping.
  - [x] Run the `push_device_tokens` migration on the VPS.
  - [ ] Create/configure the Firebase project for Android/iOS push.
  - [ ] Add Firebase client values to `flutter_app/.env` and rebuild the APK.
  - [ ] Add Laravel/VPS FCM credentials: `FCM_PROJECT_ID` plus `FCM_SERVICE_ACCOUNT_JSON` or `FCM_SERVICE_ACCOUNT_PATH`.
  - [ ] Clear VPS config cache and restart PM2 after adding FCM credentials.
  - [ ] Manually test Android push in foreground, background, terminated-app, and notification-tap flows.
  - [ ] Configure iOS APNs key/capability in Firebase/Apple before iOS push release.
  - [ ] Manually test iOS push in foreground, background, terminated-app, and notification-tap flows.

## Priority 3: MVP Product Functionality

- Creator reputation and ranking:
  - [ ] Add a `collaboration_reviews` backend table with collaboration id, reviewer id, reviewed user id, reviewer role, 1-5 rating, public comment, private feedback, review status, moderation fields, and timestamps.
  - [ ] Allow each side to leave one review per completed collaboration: brand reviews creator, creator reviews brand.
  - [ ] Add required 1-5 star rating and optional public comment after collaboration completion.
  - [ ] Add optional private feedback visible only to admins for moderation/product quality.
  - [ ] Add review categories for richer ranking: communication, quality, deadline/reliability, professionalism, and would-work-again.
  - [ ] Add backend review endpoints: create review, update within a short edit window, list reviews for a creator/brand profile, and admin hide/restore review.
  - [ ] Add Flutter review prompt when a collaboration is completed and a review is still missing.
  - [ ] Add Flutter review form with star rating, category ratings, public comment, private feedback, and submit confirmation.
  - [ ] Add review summaries on creator and brand profiles: average rating, review count, latest comments, completed jobs, and reliability badge.
  - [ ] Add review notifications: remind reviewer after completion, notify reviewed user when a public review is published, notify admins when a review is reported.
  - [ ] Add report review flow so users can flag abusive/fake comments.
  - [ ] Add a `creator_reputation_scores` backend table or computed materialized model for completed jobs, average rating, review count, approval rate, revision rate, cancellation rate, response speed, recent activity, and score version.
  - [ ] Calculate a creator ranking score from internal marketplace behavior first: completed collaborations, ratings, review quality, deliverable approval rate, reliability, and recency.
  - [ ] Surface average rating, completed-collaboration count, and reliability badge on public creator profiles.
  - [ ] Sort brand creator discovery by recommended/ranking score, with filters for rating, completed jobs, category, platform, location, and availability.
  - [ ] Add admin controls to inspect/override suspicious reputation scores, moderate comments, and hide abusive reviews.
- Safety and moderation:
  - [ ] Add report-user/report-collaboration flow.
  - [ ] Add admin moderation queue for reported users, reported collaborations, and suspicious profiles.
- Collaboration lifecycle:
  - [ ] Add "revision requested" deliverable status with required feedback.
  - [ ] Allow creators to resubmit a rejected/revision-requested deliverable.
  - [ ] Add clearer collaboration timeline states: accepted, in progress, awaiting deliverable, revision requested, approved, completed, cancelled.
  - [ ] Add cancellation reason and optional admin review flag.
- Brand growth tools:
  - [ ] Add saved/favorite creators for brands.
  - [ ] Add invite creator to announcement/collaboration flow.
  - [ ] Add creator shortlist inside an announcement.
- MVP payment stance:
  - [ ] Decide whether MVP payments are handled outside the app or tracked inside the app.
  - [ ] If external, add clear collaboration/payment instructions and manual payment-status tracking.
  - [ ] If internal later, design payment provider, commission, payout, invoice, refund, and dispute workflows.
- Later social metrics enrichment:
  - [ ] Keep social follower/subscriber count outside the MVP ranking core until the internal reputation system is working.
  - [ ] Add a `creator_social_accounts` backend table for platform, profile URL, handle, platform user id, follower/subscriber count, source, confidence, sync status, last synced timestamp, and verification status.
  - [ ] Add creator onboarding/profile fields for social profile URLs/handles that our backend can enrich without requiring creator OAuth.
  - [ ] Add YouTube public channel stats sync using YouTube Data API for subscriber/video/view counts where available.
  - [ ] Add Instagram/Meta public-business discovery where official APIs allow our app to read public Business/Creator account metrics without each creator connecting their account.
  - [ ] Add TikTok follower-count strategy: official no-OAuth lookup if available, otherwise manual/admin verification or a vetted data provider; do not rely on fragile scraping as the core path.
  - [ ] Add a manual follower-count fallback with screenshot/admin verification for platforms or account types that cannot be synced automatically.
  - [ ] Store social metric snapshots so brands can see last verified count, source, confidence, and last sync date, not just a raw number.

## Priority 4: UX And Mobile Polish

- [x] Add loading, empty, and error states for primary list screens.
- [x] Add pull-to-refresh on list-heavy screens, including empty/error states.
- [x] Add cursor pagination for collaboration chat messages.
- Add pagination/infinite scrolling for remaining long list screens where backend responses support it.
- [x] Standardize status labels and colors across announcements, applications, collaborations, and submissions.
- [x] Improve attachment previews for PDF/video files.
- [x] Add image/file size validation feedback before upload.
- [x] Add offline/network failure messaging for API and websocket failures.

## Priority 5: Backend/API Hardening

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
- Add pagination contracts for announcements, applications, collaborations, notifications, and creator discovery.
- Add API rate limiting for auth, application submit, message send, deliverable submit, and social metric sync endpoints.
- Add audit logs for admin-sensitive actions: profile verification, report handling, user suspension, collaboration cancellation, and metric verification.

## Priority 6: Release Readiness

- Add Flutter integration tests for login, onboarding, announcement browsing, applying, chat, deliverable submission, and notification navigation.
- Add environment documentation for Flutter `.env`, backend API URL, Reverb host/port/key/scheme, and storage URL.
- Add build scripts/checklist for Android and iOS.
- Add CI steps for `php artisan test`, `flutter analyze`, and `flutter test`.
- Review app icons, splash screen, permissions, package IDs, and signing configuration.
- Add closed-beta QA checklist for Android devices covering signup, onboarding, announcement creation, apply, accept/reject, chat, deliverables, notifications, and logout/login.
- Add production operations checklist for VPS backups, queue workers, Reverb, PM2 processes, storage symlink, logs, and deploy rollback.

## Current Verification

- Latest full pass, 2026-06-13:
  - `php artisan test`: passing, 46 tests / 171 assertions.
  - `flutter analyze`: passing with no issues.
  - `flutter test`: passing.
- Latest APK build after chat pagination, 2026-06-13:
  - `flutter build apk --release`: passing.
  - Test APK copied to `celibrity_flutter_test.apk`.

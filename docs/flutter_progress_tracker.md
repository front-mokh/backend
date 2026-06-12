# Flutter Progress Tracker

Last updated: 2026-06-12

Use this file as the quick handoff between sessions. The detailed roadmap lives in `docs/flutter_parity_todo.md`.

## Current Status

- Flutter app exists in `flutter_app/` and is now connected more closely to the Laravel backend.
- Collaboration chat now supports realtime messages, realtime read receipts, visible sent/seen states, and live unread badges in collaboration lists.
- Onboarding now keeps draft state live while users type and gives incomplete-profile users a clear logout path.
- Creator/brand onboarding retries now update existing profiles instead of crashing with duplicate-profile errors.
- Brand announcement creation now refreshes the announcement list immediately after a successful publish.
- Brand and creator profile tabs now refresh profile data on open and no longer render a duplicate inner "Profil" app bar.
- Backend and Flutter quality checks are green.
- React Native app in `react_native_app/mobile` remains the feature reference for parity.
- `flutter_app/` is currently untracked in git, so remember to include it intentionally when committing.

## Completed

- [x] Mapped the project components: Laravel backend, database/seeders, React Native reference app, Flutter app, tests.
- [x] Created detailed parity roadmap in `docs/flutter_parity_todo.md`.
- [x] Added Laravel collaboration completion support in `CollaborationController::complete`.
- [x] Restricted announcement creation to brand users in `AnnouncementController::store`.
- [x] Fixed Flutter social link parsing when backend does not return a `platform`.
- [x] Fixed Flutter deliverable submission parsing for backend `deliverable_type` relation names.
- [x] Replaced Flutter realtime setup with Reverb-compatible websocket private-channel auth.
- [x] Added collaboration chat realtime handling for brand and creator screens.
- [x] Added collaboration read tracking and heartbeat presence from Flutter.
- [x] Added chat file attachment upload and previews in collaboration detail screens.
- [x] Fixed brand deliverable approval buttons for backend `submitted` status.
- [x] Added notification tap navigation from backend route payloads to Flutter routes.
- [x] Added unread notification badges to brand and creator shells.
- [x] Added profile as a bottom navigation tab for brand and creator.
- [x] Added social links to brand and creator profile screens.
- [x] Replaced default Flutter counter test with a real app smoke test.
- [x] Cleaned Flutter analyzer issues.
- [x] Added backend `message.read` broadcast event for chat read receipts.
- [x] Made `/api/collaborations/{id}/read` return read-state payloads and mark incoming messages as read.
- [x] Added socket-id headers to Flutter API calls for cleaner Laravel broadcast echo handling.
- [x] Upgraded Flutter websocket service with broadcast streams, reconnect/backoff, and reference-counted private-channel subscriptions.
- [x] Added visible `Envoyé` / `Vu` read receipt UI to brand and creator chat bubbles.
- [x] Added realtime collaboration-list unread badge updates for brand and creator inboxes.
- [x] Added backend chat read-tracking feature tests.
- [x] Improved Flutter onboarding state management with live draft updates, persisted step selections, and an exit/logout action.
- [x] Fixed backend onboarding double-submit crashes and Flutter onboarding error messages for failed submits.
- [x] Fixed brand announcement list refresh after creating a new announcement.
- [x] Removed duplicate profile headers from brand and creator profile tabs.
- [x] Added profile refresh-on-open and pull-to-refresh so phone/location/profile changes are not stuck on stale cached data.
- [x] Audited Flutter screens for placeholder or incomplete implementation.

## Missing Or Stubbed Flutter Screens

- [ ] Brand creator discovery (`/brand/creators`): currently only shows "Bientôt disponible".
- [ ] Brand edit announcement (`/brand/edit-announcement/:id`): currently only shows the announcement id.
- [ ] Creator application details (`/creator/application/:id`): currently only shows the application id.

## Implemented But Still Behind React Native

- [ ] Creator announcement discovery needs search and filters for category, budget, tier, and deadline.
- [ ] Brand announcement management needs search, filters, sorting, and clearer application counts.
- [ ] Brand and creator collaboration lists need stronger search/filter/status polish.
- [ ] Collaboration detail screens need fuller summary/status tabs and completed/cancelled action locking.

## Verified

- [x] `php artisan test` passes: 27 tests, 87 assertions.
- [x] `flutter analyze` passes with no issues.
- [x] `flutter test` passes.

## Next Session: Start Here

1. Implement the missing Brand Creators discovery page.
2. Implement Brand Edit Announcement using the existing create form/backend update flow.
3. Implement Creator Application Details.
4. Add collaboration details/summary tabs for both roles.
5. Add visible brand action to complete a collaboration using `ApiService.completeCollaboration`.
6. Add completed/cancelled UI states so users understand when actions are locked.
7. Add creator announcement search and filters for category, budget, tier, and deadline.
8. Add stronger brand announcement list search/filter/sort and surface application counts.

## Known Risks / Watch Items

- Manual device testing is still needed against the live Reverb server to confirm environment values, TLS/port access, and mobile network behavior.
- Flutter push notifications still need a proper Firebase Cloud Messaging strategy; backend push flow appears Expo-oriented.
- Notification route mapping covers the known routes from this pass, but every backend notification type still needs a full audit.
- Backend feature tests should still be added for announcement creation permissions and collaboration completion permissions.

## Worktree Notes

- Expected new/changed files from this pass include:
  - `docs/flutter_parity_todo.md`
  - `docs/flutter_progress_tracker.md`
  - `app/Http/Controllers/Api/AnnouncementController.php`
  - `app/Http/Controllers/Api/CollaborationController.php`
  - `app/Events/MessageReadEvent.php`
  - `tests/Feature/ChatReadTrackingTest.php`
  - `flutter_app/`
- Existing unrelated or pre-existing worktree items seen during this pass:
  - `eas.json`
  - `app.json`
  - `react_native_app/mobile`

## Resume Checklist

- [ ] Run `git status --short`.
- [ ] Confirm `flutter_app/.env` points to the intended backend/Reverb environment.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `php artisan test` after backend changes.
- [ ] Update this file before ending the next session.

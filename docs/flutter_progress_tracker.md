# Flutter Progress Tracker

Last updated: 2026-06-12

Use this file as the quick handoff between sessions. The detailed roadmap lives in `docs/flutter_parity_todo.md`.

## Current Status

- Flutter app exists in `flutter_app/` and is now connected more closely to the Laravel backend.
- Collaboration chat now supports realtime messages, realtime read receipts, visible sent/seen states, and live unread badges in collaboration lists.
- Onboarding now keeps draft state live while users type and gives incomplete-profile users a clear logout path.
- Creator/brand onboarding retries now update existing profiles instead of crashing with duplicate-profile errors.
- Creator/brand onboarding completion now refreshes state safely after submit and no longer loops back to the profile info step when social links serialize booleans as `0/1`.
- Flutter now keeps the root GoRouter stable across auth refreshes so brand/creator profile tabs do not bounce back to the default announcements page.
- Creator announcement details now use a richer modern layout with safe-area bottom actions and visible existing-application state.
- Creator announcement details now group expected deliverables by platform so creators can see which deliverable belongs to which channel.
- Creator/brand application detail actions now use SafeArea bottom footers to avoid Android bottom-area overlap.
- Creator collaboration deliverable submission now uses platform-first selection, then specific deliverable selection, and shows real backend validation messages.
- Creator applications now block duplicate applies in the UI, while the backend returns a French `409` conflict if a duplicate submit still happens.
- Brand announcement creation now refreshes the announcement list immediately after a successful publish.
- Brand and creator profile tabs now refresh profile data on open and no longer render a duplicate inner "Profil" app bar.
- Priority 1 Flutter parity now covers creator discovery, announcement editing, application details, collaboration summary/status tabs, and search/filter headers on the main list screens.
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
- [x] Fixed post-onboarding refresh parsing for social links and messages with numeric boolean values.
- [x] Added a backend cast for `SocialLink::is_verified` and deployed it to the VPS.
- [x] Fixed root router recreation during profile refreshes, which sent brand users from Profile back to Announcements.
- [x] Redesigned the creator announcement detail page with hero media, compact info tiles, sections, attachment access, and a SafeArea action footer.
- [x] Grouped creator announcement deliverables under their platform instead of showing disconnected platform/deliverable sections.
- [x] Added `current_user_application` to announcement details for creators and used it to replace duplicate apply buttons with "Voir ma candidature".
- [x] Moved creator "Voir l'annonce" and brand "Ouvrir la collaboration" application-detail actions into SafeArea footers.
- [x] Added platform-first deliverable submission in creator collaboration details and backend validation for requested deliverables.
- [x] Improved the creator apply form with SafeArea footer actions, integer budget submission, and cleaner API error messages.
- [x] Added backend tests for duplicate application rejection and current creator application payloads.
- [x] Fixed brand announcement list refresh after creating a new announcement.
- [x] Removed duplicate profile headers from brand and creator profile tabs.
- [x] Added profile refresh-on-open and pull-to-refresh so phone/location/profile changes are not stuck on stale cached data.
- [x] Audited Flutter screens for placeholder or incomplete implementation.
- [x] Added backend `GET /api/creators` for brand-side creator discovery.
- [x] Added backend `GET /api/applications/{application}` with owner/brand authorization.
- [x] Added backend feature tests for creator discovery and application details access.
- [x] Implemented Flutter Brand Creators discovery with search, category filters, creator cards, and detail sheet.
- [x] Replaced Brand Edit Announcement placeholder with the shared create/edit announcement form.
- [x] Replaced Creator Application Details placeholder with a real status/detail/navigation screen.
- [x] Fixed Brand Application Details to load a single application by id and support accept/reject/open collaboration.
- [x] Added search/filter/count headers to brand announcements, creator announcements, creator applications, and both collaboration inboxes.
- [x] Added collaboration details tabs for brand and creator.
- [x] Added visible brand action to complete a collaboration and locked UI states for completed/cancelled collaborations.

## Missing Or Stubbed Flutter Screens

- [x] Brand creator discovery (`/brand/creators`) is implemented.
- [x] Brand edit announcement (`/brand/edit-announcement/:id`) is implemented.
- [x] Creator application details (`/creator/application/:id`) is implemented.

## Implemented But Still Behind React Native

- [ ] Creator announcement discovery has search/category filters; budget, tier, and deadline filters still need advanced controls.
- [ ] Brand announcement management has search/status filters and application counts; explicit sort controls are still pending.
- [ ] Brand-side application filtering by status inside announcement details can be improved further.

## Verified

- [x] `php artisan test` passes: 31 tests, 100 assertions.
- [x] `flutter analyze` passes with no issues.
- [x] `flutter test` passes.

## Next Session: Start Here

1. Add advanced creator announcement filters for budget, tier, and deadline.
2. Add explicit brand announcement sort controls.
3. Add brand-side status filtering inside announcement application lists.
4. Manually test Priority 1 flows on Android against the VPS: creator discovery, edit announcement, application accept/reject, open collaboration, complete collaboration.

## Known Risks / Watch Items

- Manual device testing is still needed against the live Reverb server to confirm environment values, TLS/port access, and mobile network behavior.
- Flutter push notifications still need a proper Firebase Cloud Messaging strategy; backend push flow appears Expo-oriented.
- Notification route mapping covers the known routes from this pass, but every backend notification type still needs a full audit.
- Backend feature tests should still be added for announcement creation permissions and collaboration completion permissions.
- New `/api/creators` endpoint is intentionally brand-only and returns the first 100 onboarded creators; pagination can be added when creator volume grows.

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

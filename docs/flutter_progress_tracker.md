# Flutter Progress Tracker

Last updated: 2026-06-13

Use this file as the quick handoff between sessions. The detailed roadmap lives in `docs/flutter_parity_todo.md`.

## Current Status

- Flutter app exists in `flutter_app/` and is now connected more closely to the Laravel backend.
- Collaboration chat now supports cursor-paginated history loading, realtime messages, realtime read receipts, visible sent/seen states, and live unread badges in collaboration lists.
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
- Flutter push notifications now use a Firebase Cloud Messaging path with backend device-token registration, token refresh/logout cleanup, foreground local notifications, and push tap route mapping.
- FCM code is implemented but real phone push still needs Firebase project credentials in Flutter `.env` and Laravel/VPS env before live delivery.
- MVP reputation is now underway: completed collaborations can be reviewed by both sides, public comments/category ratings are stored, creator discovery shows reputation chips, and discovery is sorted by the computed reliability score.
- Hidden reviews are excluded from mobile payloads and reputation summaries, ready for the later moderation controls.
- Review edge cases were re-evaluated: authors still receive their own hidden-review state, duplicate review races return a clean validation response, and the Flutter review sheet blocks mid-submit dismissal.
- Backend and Flutter quality checks are green.
- React Native app in `react_native_app/mobile` is legacy reference material only; active product work is Laravel backend plus Flutter mobile.

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
- [x] Added Flutter/Laravel Firebase Cloud Messaging infrastructure for Android/iOS push notifications.
- [x] Added `push_device_tokens` persistence with hashed token lookup and multi-device support.
- [x] Added `/api/push-tokens` register/delete endpoints plus legacy Expo endpoint compatibility.
- [x] Added Flutter token registration on login/session restore, token cleanup on logout, foreground notification display, and notification tap deep-link handling.
- [x] Added backend feature tests for push-token registration, validation, deletion, and legacy Expo compatibility.
- [x] Deployed the push-token backend files to the VPS, ran `php artisan migrate --force`, cleared caches, and restarted `celebrity_back`.
- [x] Added `GET /api/collaborations/{collaboration}/messages` with cursor pagination, authorization, and a message lookup index.
- [x] Updated brand and creator Flutter collaboration chats to load the latest 30 messages first and load older messages on request.
- [x] Kept realtime message append/read-receipt behavior working without re-fetching the full collaboration after every send.
- [x] Deployed the chat-pagination backend files to the VPS, ran the message index migration, cleared caches, and restarted `celebrity_back`.
- [x] Added `collaboration_reviews` with one review per participant per completed collaboration.
- [x] Added backend create-review validation, review notifications, user reputation summaries, and creator discovery sorting by reliability score.
- [x] Added Flutter review prompts/forms to brand and creator completed collaboration detail pages.
- [x] Added public collaboration review display and creator discovery reputation chips/detail panel.
- [x] Added regression coverage so hidden reviews do not leak into collaboration responses or reputation summaries.
- [x] Hardened current-user hidden review state and duplicate-review race handling.
- [x] Hardened the Flutter review bottom sheet against dismissal during submit.

## Missing Or Stubbed Flutter Screens

- [x] Brand creator discovery (`/brand/creators`) is implemented.
- [x] Brand edit announcement (`/brand/edit-announcement/:id`) is implemented.
- [x] Creator application details (`/creator/application/:id`) is implemented.

## Implemented But Still Behind React Native

- [ ] Creator announcement discovery has search/category filters; budget, tier, and deadline filters still need advanced controls.
- [ ] Brand announcement management has search/status filters and application counts; explicit sort controls are still pending.
- [ ] Brand-side application filtering by status inside announcement details can be improved further.

## Verified

- [x] `php artisan test` passes: 53 tests, 213 assertions.
- [x] `flutter analyze` passes with no issues.
- [x] `flutter test` passes: 4 tests.
- [x] `flutter build apk --release` passes after MVP reviews/reputation.
- [x] Latest `celibrity_flutter_test.apk` SHA-256: `7b0e3f228036921033a80de6ee50a7c79a027345d55f2d50823a627f570f0ade`.

## Next Session: Start Here

1. Create/configure the Firebase project for Android/iOS push.
2. Add Firebase client values to `flutter_app/.env`.
3. Add Laravel/VPS FCM credentials: `FCM_PROJECT_ID` plus `FCM_SERVICE_ACCOUNT_JSON` or `FCM_SERVICE_ACCOUNT_PATH`.
4. Clear VPS config cache and restart PM2 after adding FCM credentials.
5. Rebuild the APK after Firebase client values are present.
6. Manually test Android push: foreground, background, terminated app, and tap-to-open route.
7. Configure Apple APNs key/capability in Firebase before testing iOS push.
8. Manually test iOS push: foreground, background, terminated app, and tap-to-open route.
9. Continue MVP product-depth work: review edit window, profile review lists, private/admin feedback, report-review flow, admin moderation, saved creators, creator invitations, and deeper reputation scoring from deliverable approval/cancellation/response-speed signals.

## Known Risks / Watch Items

- Manual device testing is still needed against the live Reverb server to confirm environment values, TLS/port access, and mobile network behavior.
- FCM delivery cannot be proven until Firebase project credentials are added to Flutter and the VPS backend.
- iOS push needs Apple APNs key/capability configured in Firebase; FCM itself is no-cost, but Apple distribution/testing may require the normal Apple developer setup.
- Notification route mapping covers the known routes from this pass, but every backend notification type still needs real-device tap testing.
- Backend feature tests should still be added for announcement creation permissions and collaboration completion permissions.
- New `/api/creators` endpoint is intentionally brand-only and returns the first 100 onboarded creators; pagination can be added when creator volume grows.
- Social follower counts are postponed until after the internal reputation system. MVP ranking should use marketplace behavior first; external social stats can be added later as an enrichment signal where official APIs allow it.
- Reputation summaries are computed on demand for now. This is fine for MVP volume, but should move to aggregate queries or a materialized score table before creator volume grows.
- Review moderation is still basic: reviews have a status field, but admin hide/restore, report review, private feedback, and edit-window flows are still pending.

## Worktree Notes

- Expected new/changed files from this pass include:
  - `app/Http/Controllers/Api/CollaborationController.php`
  - `app/Http/Controllers/Api/CollaborationReviewController.php`
  - `app/Http/Controllers/Api/UserController.php`
  - `app/Models/Collaboration.php`
  - `app/Models/CollaborationReview.php`
  - `app/Models/User.php`
  - `routes/api.php`
  - `database/migrations/2026_06_13_000003_create_collaboration_reviews_table.php`
  - `database/migrations/2026_06_13_000002_add_cursor_index_to_messages_table.php`
  - `tests/Feature/CollaborationReviewTest.php`
  - `tests/Feature/ChatReadTrackingTest.php`
  - `flutter_app/lib/core/models/models.dart`
  - `flutter_app/lib/core/services/api_service.dart`
  - `flutter_app/lib/core/widgets/collaboration_review_section.dart`
  - `flutter_app/lib/features/brand/screens/creators_screen.dart`
  - `flutter_app/lib/features/brand/screens/collaboration_details_screen.dart`
  - `flutter_app/lib/features/creator/screens/creator_collaboration_details_screen.dart`
  - `docs/flutter_parity_todo.md`
  - `docs/flutter_progress_tracker.md`
- Existing unrelated or pre-existing worktree items seen during this pass:
  - `eas.json`
  - `app.json`
  - `celibrity_flutter_test.apk`
  - `react_native_app/mobile`

## Resume Checklist

- [ ] Run `git status --short`.
- [ ] Confirm `flutter_app/.env` points to the intended backend/Reverb environment.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `php artisan test` after backend changes.
- [ ] Update this file before ending the next session.

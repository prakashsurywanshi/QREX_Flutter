# QREX Flutter Readiness Gaps

## Current state
- Feature modules/scaffolding present for core parity areas (auth, leads, pipeline, bookings, payments, commissions, projects/units, communications, settings/reports, notifications).
- Branch: `feature/final-push` (local).

## Pending for production/store readiness
- Verify API contract parity against current QREX API (auth, tenant headers, pagination/error shape, IDs).
- FCM end-to-end: token registration, foreground/background handling, deep links, permission prompts.
- White-label runtime: logo/colors/name from tenant branding endpoint; app icon/splash per build flavor.
- Android release: signing config, `applicationId`, versioning, Play Console assets, privacy policy, crash reporting.
- iOS prep: bundle ID, signing/provisioning, push certs, App Store assets.
- QA: offline/error states, empty/loading states, permission/role guards, tablet/responsive, accessibility basics.
- CI: `flutter analyze`, `flutter test`, build apk/appbundle in pipeline.

## Blockers in this environment
- Flutter SDK not installed in CLI environment; cannot run analyze/test/build here.
- GitHub push blocked by credentials.

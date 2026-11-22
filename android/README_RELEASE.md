# Android Release Prep (Android-first)

## Local/CI checks
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- Release: `flutter build appbundle --release` (requires signing)

## Required before Play Store
- Set unique `applicationId` in `android/app/build.gradle.kts`
- Configure signing: `android/key.properties` (not committed) + keystore
- Set app name/icon/splash/branding flavor per tenant/white-label build
- Configure Firebase: `android/app/google-services.json`, FCM sender/project
- Verify privacy policy, data safety, permissions, notifications disclosure
- Test on real Android devices: auth, offline, deep links, FCM foreground/background

## Env/API
- Point API base URL to production HTTPS
- Confirm tenant/branding headers and auth token flow with QREX API

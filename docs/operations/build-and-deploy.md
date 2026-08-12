# Operations: build & deploy

How to build the Flutter client and ship APKs to a phone or a static host.

## Prerequisites

- Flutter SDK ≥ 3.12. The current build host has 3.44.8.
- Android SDK 35 (compileSdk) — Kodmoz build host has 35 + 36 installed.
- Java 17. PATH must include `jdk-17.0.19+10`.
- For Web: nothing extra (CanvasKit is bundled).
- For iOS / macOS: a Mac with Xcode + CocoaPods.
- For Linux: GTK 3 dev headers.
- For Windows: Developer Mode enabled in Windows Settings
  (`ms-settings:developers`).

## Build commands

All commands assume the cwd is `C:\Kodmoz\mobile\kodmoz_notebook\`.

```bash
# Re-fetch dependencies after a pubspec change
flutter pub get

# Lint (must report "No issues found!" before shipping)
flutter analyze

# Run unit + smoke tests
flutter test

# Live API probe (requires the bearer token; see architecture/auth.md)
dart run test/integration_smoke.dart
```

### Android APK

```bash
flutter build apk --debug      # → build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release    # → build/app/outputs/flutter-apk/app-release.apk
```

Release APK is signed with the **debug keystore** — fine for internal QA
and Sideload, **not** for Play Store. To ship to Play Store, generate a
proper keystore and put the path + passwords in
`android/key.properties`, then add a `signingConfig` to
`android/app/build.gradle.kts`.

### Web

```bash
flutter create --platforms=web .        # first time only
flutter build web --release
# → build/web/  (deploy to any static host: kodmoz-web, Cloudflare Pages, etc.)
```

The web build uses CanvasKit (large but consistent) by default. Add
`--wasm` to also produce a WebAssembly bundle — the upstream Flutter docs
flag this as experimental.

### iOS / macOS

Requires a Mac. On the Mac:

```bash
cd ios && pod install && cd ..      # after every pubspec change
flutter build ios --release --no-codesign
open ios/Runner.xcworkspace
# In Xcode: Product → Archive → Distribute App
```

### Linux

Requires Linux with GTK dev headers. On Debian/Ubuntu:

```bash
sudo apt install libgtk-3-dev libwebkit2gtk-4.0-dev clang cmake ninja-build
flutter create --platforms=linux .
flutter build linux --release
```

### Windows

Requires Developer Mode enabled. On Windows:

```powershell
flutter create --platforms=windows .
flutter build windows --release
```

## Install APK on Android

```bash
# USB-connected device with USB debugging enabled
adb install build/app/outputs/flutter-apk/app-release.apk

# Or copy the APK to the phone and open it in a file manager;
# you will need to allow "Install unknown apps" for that manager.
```

## Deploy web build

```bash
# rsync / scp / rclone / kodmoz-web-deploy — whichever you prefer.
# The output directory is build/web/ — it's already a static site.
rsync -av --delete build/web/ deploy@kodmoz:/srv/notebook-web/
```

Suggested mapping: serve `notebook-web` at `notebook.kodmoz.com/web/`. The
mobile app does not consume this — it's a fallback for desktop browsers.
If you want to make it the canonical UI, point a Cloudflare Access rule
at it instead of the FastAPI path.

## Verifying a new build

Before declaring "shipped":

1. `flutter analyze` → 0 issues.
2. `flutter test` → all pass.
3. `dart run test/integration_smoke.dart` → ALL OK against
   `notebook.kodmoz.com`.
4. `flutter build apk --release` → APK exists, ~50 MB.
5. Sideload the APK to your phone, log in with the shared password,
   create a notebook, add a note, send a chat message — all four flows
   should work end to end. If any flow 401s, the token was lost; sign
   out and back in.

## Verifying the backend is alive

If the app shows a generic 5xx, check the backend first:

```bash
# Is the FastAPI pod up?
kubectl -n open-notebook get pods -l app=open-notebook

# Is the bearer token still correct?
PW=$(kubectl -n open-notebook get secret open-notebook-secrets \
     -o jsonpath='{.data.app-password}' | base64 -d)
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer $PW" \
  https://notebook.kodmoz.com/api/notebooks
# Expect 200 with a JSON array.
```

If the worker pod is down, async jobs (podcasts, source processing,
embedding rebuild) will queue forever without erroring. Restart it:

```bash
kubectl -n open-notebook rollout restart deployment/open-notebook
```

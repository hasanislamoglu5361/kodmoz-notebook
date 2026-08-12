---
name: kodmoz-flutter-mobile
description: "Flutter apps for Kodmoz. Use for Android/iOS subdomain app."
version: 1.0.0
author: Aura
license: MIT
platforms: [windows, macos, linux]
metadata:
  hermes:
    tags: [flutter, mobile, android, ios, kodmoz, rest-api]
---

# Kodmoz Flutter Mobile Apps

Build and ship Flutter mobile clients for Kodmoz's web services. The first instance is `kodmoz_agents` (live, `C:\Kodmoz\mobile\agents\`), serving `agents.kodmoz.com`'s FastAPI backend. Future instances follow the same shape: a single codebase, Android APK + iOS bundle, Material 3 dark theme, REST client → models → screens.

## Trigger

- Hasan asks for "mobile app" / "Android app" / "iOS app" of any `*.kodmoz.com` subdomain.
- Adding a new screen, fixing a build, or shipping an update to an existing Flutter project under `C:\Kodmoz\mobile\`.
- Deploying a Flutter app to a phone for QA.

## Architecture (proven, August 2026, `kodmoz_agents`)

```
lib/
  main.dart                       # MaterialApp, dark theme, _RootShell (4-tab NavigationBar)
  api/api_client.dart             # one ApiClient class, one private _getJson() helper
  models/                         # one file per resource, all with fromJson() factories
    summary.dart                  # /api/summary
    agent.dart                    # /api/agents + /api/agents/{id}/history + /api/agents/sla
    task.dart                     # /api/tasks (list, summary form)
    task_detail.dart              # /api/tasks/{id} (task + events[] + runs[])
    timeline.dart                 # /api/timeline
  screens/                        # one file per screen; StatefulWidget + Future<_Data> + RefreshIndicator
    home_screen.dart              # summary tiles + active tasks + agent list (drill-down)
    tasks_screen.dart             # status-filtered task list (ChoiceChip row)
    task_detail_screen.dart       # full task: header + meta grid + body + blocked reason + events + runs
    agents_screen.dart            # agent cards with SLA badges
    agent_detail_screen.dart      # last-50 history
    timeline_screen.dart          # bar chart + bucket table, time-range chips
  widgets/
    status_badge.dart             # palette-driven status pill, shared with all screens
    stat_tile.dart                # compact metric tile for the home grid
    format.dart                   # fmtUnix / fmtRelative / fmtDuration helpers
```

Conventions that paid off:
- **One `ApiClient` per app, owned by `_RootShell`**, passed into screens as `api: widget.api`. No global singletons, no DI framework. Easy to swap base URL for staging.
- **StatefulWidget + `Future<_Data>` + RefreshIndicator** on every list screen. No Riverpod/Bloc — overkill for these read-mostly dashboards.
- **Drill-down via `Navigator.push` + `MaterialPageRoute`**, taking the api + ID. Stateless screens stay composable.
- **Status colour palette** lives in `status_badge.dart`'s `_palette` map — same colours everywhere. Add a new status by extending the map, not editing screens.
- **Material 3 dark theme** with `colorSchemeSeed: 0xFF2563EB` (kodmoz blue) and `scaffoldBackgroundColor: 0xFF0F1115`. `themeMode: ThemeMode.dark` hardcoded — kodmoz brand is dark-first.
- **IndexedStack + KeyedSubtree** for the bottom-nav so each tab keeps its scroll/future state across switches.

## Android build (Windows host)

Critical PATH + alias issues that bit me on the first install — fix BEFORE running `flutter create`:

1. **Flutter SDK lives at `C:\Users\ben\flutter-sdk`** (not `/c/flutter` — that one is empty). Real SDK has `bin/flutter.bat`.
2. **`flutter.bat` shells out to `where.exe` and `pwsh.exe`** — both must be on PATH. The minimum set:
   ```bash
   export PATH="/c/Program Files/PowerShell/7:/c/WINDOWS/system32:/c/Users/ben/flutter-sdk/bin:/mingw64/bin:/usr/bin:/c/Program Files/Git/cmd:$PATH"
   ```
   Without `/c/WINDOWS/system32` first you'll see `'WHERE' is not recognized`; without PowerShell 7 you'll see `Unable to determine engine version`.
3. **The `bash` command is shadowed by Windows App Execution Alias** (see `## bash hash override` below). Never write a wrapper script with `#!/usr/bin/env bash` shebang — use `#!/usr/bin/env sh`. `flutter` wrapper lives at `/c/Users/ben/bin/flutter` and shells out to `cmd.exe /c flutter.bat`.
4. **Accept Android SDK licenses once**: `yes | flutter doctor --android-licenses` (interactive if piped, so use `yes |`).

Project creation:

```bash
cd /c/Kodmoz/mobile
flutter create --platforms=android,ios --org com.kodmoz --project-name <name> <name>
cd <name>
flutter pub get
```

Edit `android/app/build.gradle.kts`:
```kotlin
android {
    namespace = "com.kodmoz.<name>"        // short, NOT com.kodmoz.<name>_<name>
    applicationId = "com.kodmoz.<name>"    // ditto
    minSdk = 23                            // explicit — flutter.minSdkVersion drifts
    ...
}
```

Edit `android/app/src/main/AndroidManifest.xml`:
- Add `<uses-permission android:name="android.permission.INTERNET"/>` at the top of `<manifest>`
- Set `android:label="Kodmoz <Name>"` (capitalised, with space)
- Set `android:usesCleartextTraffic="false"` — Kodmoz APIs are HTTPS-only

Build APKs:

```bash
flutter build apk --debug      # → build/app/outputs/flutter-apk/app-debug.apk (~140MB)
flutter build apk --release    # → build/app/outputs/flutter-apk/app-release.apk (~50MB)
```

Release APK is signed with debug keys by default (acceptable for internal QA; production needs a real keystore in `android/key.properties` + signingConfig in `build.gradle.kts`). Install via:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

`flutter analyze` should return 0 errors / 0 warnings before shipping. Info-level lints (style) are OK to ignore.

## iOS build

Cannot be built on this Windows host — needs macOS + Xcode + CocoaPods. The Flutter project is created with `--platforms=android,ios`, so the iOS Runner is generated automatically. Before shipping to a Mac:

1. Edit `ios/Runner/Info.plist`:
   - `CFBundleDisplayName` = `"Kodmoz <Name>"` (Flutter sets this on creation; verify)
   - Add `NSAppTransportSecurity` dict if any HTTP fallback is needed (Kodmoz uses HTTPS, so not needed)
2. Edit `ios/Runner.xcodeproj/project.pbxproj` for `PRODUCT_BUNDLE_IDENTIFIER = com.kodmoz.<name>`.
3. On the Mac:
   ```bash
   cd ios && pod install && cd ..
   flutter build ios --release --no-codesign
   open ios/Runner.xcworkspace   # then Product → Archive in Xcode for App Store / TestFlight
   ```

If Hasan wants the iOS build on his Mac, ask whether he wants me to ship the `C:\Kodmoz\mobile\<name>\` folder to him via `send.kodmoz.com` or similar — we have no Mac shell.

## `bash` hash override (Flutter-specific symptom)

When running Flutter wrappers from MSYS bash, `bash <wrapper>` fails with `No such file or directory` despite the file existing, being executable, and `cat`-readable. Root cause: Windows App Execution Alias puts `/c/WINDOWS/system32/bash.exe` ahead of `/usr/bin/bash` in PATH hash. Verified August 2026 during initial Flutter setup.

**Fix**: write all new wrapper scripts (e.g. `~/bin/flutter`, `~/bin/node-wrapper`) with shebang `#!/usr/bin/env sh`, NOT `#!/usr/bin/env bash`. `sh` is MSYS-bundled and not shadowed. Diagnosis: `type -a bash` shows `/c/WINDOWS/system32/bash` first = the Windows shim is winning.

## Pitfalls (verified live)

1. **`/c/Users/ben/flutter-sdk/bin/flutter` direct invocation fails from MSYS** — the file IS there, IS executable, but bash (shadowed) can't find it. Always invoke via `cmd.exe /c "flutter.bat"` or via the `~/bin/flutter` `sh` wrapper.
2. **Don't auto-set `applicationId` from `flutter create`** — the default is `com.kodmoz.<project_name>` with the underscore (`com.kodmoz.kodmoz_agents`). Edit to `com.kodmoz.<name>` BEFORE first build, otherwise renaming later breaks Play Store updates.
3. **`flutter doctor --android-licenses` needs `yes |` pipe** — interactive prompt otherwise hangs the terminal call.
4. **`InkWell` inside a `StatelessWidget` can't access the parent's `widget.api`** — pass via `onTap` callback from the parent, or wrap the parent in an `InheritedWidget`. Don't try to look up `widget.api` from a private `_XxxCard` widget.
5. **PATCHES to the same file in rapid succession can introduce stray `}class` / orphaned brackets** if the surrounding context is large. After every multi-patch sequence run `flutter analyze` and fix the syntax drift before continuing — `analyze` catches these in seconds.
6. **Test scaffold's `MyApp` reference** is hardcoded in `test/widget_test.dart` after `flutter create`. Replace with the real root class (`KodmozAgentsApp`, etc.) — `flutter analyze` will catch it as `error: The name 'MyApp' isn't a class`.
7. **`shared_preferences` is NOT actually used in `kodmoz_agents`** — left in pubspec from initial scaffold but unused. Drop it before locking the deps, or it'll trigger platform-channel native code at build time that isn't exercised. Same audit for any other unused dep.
8. **iOS build needs `pod install` after every pubspec change** — Flutter regenerates `ios/Runner/GeneratedPluginRegistrant.*` from pubspec; without `pod install`, plugins like `shared_preferences` will fail to link on first iOS build.
9. **`IndexedStack` keeps all tabs alive** — refreshing one tab doesn't reload the others. Use a top-right refresh button that bumps a `Key` and rebuilds all tabs (see `_RootShell._refreshAll` in `kodmoz_agents/lib/main.dart`).
10. **`flutter_secure_storage: ^9.2.4` hardcodes `compileSdk 34`** — `flutter build apk` fails with *"Failed to install the following SDK components: platforms;android-34"* if the host only has Android SDK 35/36 (Kodmoz case). On Windows the bundled `sdkmanager` frequently hangs at *"Failed to read or create install properties file"* and won't auto-install 34. Three fixes, in order of effort: (a) `shared_preferences` for token storage on a trusted single-operator device (current state in `kodmoz_notebook`); (b) override the library's compileSdk via `subprojects { afterEvaluate { project.android { if (namespace == "com.it_nomads.fluttersecurestorage") compileSdkVersion(35) } } }` in the project root `build.gradle.kts`; (c) install Android SDK 34 manually. Don't waste time on the sdkmanager auto-install path.
11. **Backend API bugs surface in mobile clients.** When the upstream service returns a 422 on a payload the client built correctly (e.g. `POST /sources` always 422 with "type required" even when `type` is in the body — Pydantic v2 reserved-name bug in Open Notebook), the client must surface the error rather than retry. Add a 422/400 unit case to your integration smoke test so the regression is caught immediately.
12. **APK too big for Telegram direct send (>45 MB)** — the release APK is ~49 MB. Don't try `MEDIA:` with a path larger than 45 MB; use the `send-media-to-telegram` skill's tmpfiles.org fallback path. Include the SHA-256 in the user message so they can verify after download.
13. **`${applicationName}` placeholder is NOT reliably substituted by the Flutter Gradle plugin.** When substitution fails the merged manifest contains `<application android:name="android.app.Application">` — the default Android Application, not Flutter's. Result: the activity launches, Flutter engine never initialises, blank screen then instant crash back to launcher with no toast. Two contributing factors we hit on `kodmoz_notebook` in August 2026: (a) `MainActivity.kt` was generated at `com/kodmoz/kodmoz_notebook/` but `namespace` was changed to `com.kodmoz.notebook` — the Kotlin file must be moved to match the namespace; (b) Flutter 3.44's Gradle plugin emits "Upgrading build.gradle.kts" during builds which can revert `minSdk = 23` back to `flutter.minSdkVersion`. **Fix in `AndroidManifest.xml`:** write `android:name="io.flutter.embedding.android.FlutterApplication"` explicitly. Do not use `FlutterPlayStoreSplitApplication` unless you've added the Play Core dependency (R8 will fail). **Always verify after every release build** by dumping the merged manifest — see `scripts/verify-flutter-manifest.sh` (cross-referenced in `kodmoz-notebook-mobile`).
14. **`aapt.exe` on this Windows host needs a native-style absolute path** (`C:\...`, not `/c/...`). MSYS-style paths produce `W asset: Asset path /c/... is neither a directory nor file (type=1)` and `dump failed because assets could not be loaded`. Invoke via PowerShell 7 (`/c/Program Files/PowerShell/7/pwsh.exe -Command "& 'C:\Android\sdk\build-tools\36.0.0\aapt.exe' ..."`) or use the `scripts/verify-flutter-manifest.sh` wrapper which handles the conversion.

## API mapping for `agents.kodmoz.com` (live, FastAPI)

Reference: `references/agents-kodmoz-api.md`. Endpoints used:

| Endpoint | Returns | File |
|---|---|---|
| `GET /api/health` | `{status, db}` | (not consumed by app) |
| `GET /api/summary` | `{activeTasks, totalAgents, idleAgents, busyAgents, completedLast24h}` | `models/summary.dart` |
| `GET /api/agents` | `[{role, status, currentTaskId, currentTaskSummary, blockedReason}]` | `models/agent.dart` |
| `GET /api/agents/{id}/history?limit=N` | `[TaskSummary]` (last N jobs) | `models/agent.dart` `AgentHistoryItem` |
| `GET /api/agents/sla` | `[{task_id, title, assignee, started_at, last_heartbeat_at, elapsed_sec, sla_sec, breached}]` | `models/agent.dart` `SlaItem` |
| `GET /api/tasks?status=&assignee=&limit=` | `[TaskSummary]` | `models/task.dart` |
| `GET /api/tasks/active` | `[TaskSummary]` (running/ready/blocked) | `models/task.dart` |
| `GET /api/tasks/{id}` | `{task, events[], runs[]}` (full detail) | `models/task_detail.dart` |
| `GET /api/timeline?hours=&bucket=` | `[{ts, iso, completed, blocked, done, archived}]` | `models/timeline.dart` |

Auth: NONE — the endpoint is currently public. If Kodmoz adds Cloudflare Access (Tier-1) in front, the app will need either a service token header (`CF-Access-Client-Id` / `CF-Access-Client-Secret`) or a cookie injection via `package:webview_flutter` for browser-based login.

## Future instances — adaptation checklist

To build `kodmoz_<other>` for another Kodmoz subdomain (e.g. `kodmoz_send` for `send.kodmoz.com`, `kodmoz_music` for `music.kodmoz.com`):

1. `flutter create --org com.kodmoz --project-name kodmoz_<other> <name>` in `C:\Kodmoz\mobile\`
2. Replace `lib/api/api_client.dart` baseUrl + endpoint methods
3. Replace `lib/models/*.dart` with the new service's schemas
4. Replace screens — keep `widgets/status_badge.dart`, `widgets/stat_tile.dart`, `widgets/format.dart` as-is (they're generic)
5. Update Android `applicationId` + `label`, iOS `CFBundleDisplayName`
6. `flutter analyze` clean → `flutter build apk --release`

The shared widgets + scaffolding should get a second app to "compiles and runs" in <30 min if the API is already documented.

## Existing instances

| App | Path | Backend | Notes |
|---|---|---|---|
| `kodmoz_agents` | `C:\Kodmoz\mobile\agents\` | `agents.kodmoz.com` (FastAPI) | August 2026 — kanban dashboard. Live on Android APK. |
| `kodmoz_notebook` | `C:\Kodmoz\mobile\kodmoz_notebook\` | `notebook.kodmoz.com` (Open Notebook, FastAPI + SurrealDB) | August 2026 — login + 5 tabs (Home/Notes/Sources/Chat/Settings). See `kodmoz-open-notebook-operations` skill for backend. |

### `kodmoz_notebook` specifics (added August 2026)

- **Auth:** single bearer token configured at the Open Notebook pod (`Kodmoz!!2026!!`). Login screen accepts it as "password", stored in `SharedPreferences`. Upgrade to `flutter_secure_storage` once Android SDK 34 is on the build host (current build host only has 35/36; `flutter_secure_storage: ^9.2.4` hardcodes `compileSdk 34`).
- **Bearer in code:** `ApiClient._headers()` adds `Authorization: Bearer <token>` to every request when `loadToken()` returns non-null.
- **Backend quirks already worked around in the app:**
  - `GET /chat/sessions` requires `notebook_id` filter (returns 422 without) — Chat tab forces user to pick a notebook
  - `POST /sources` with `type: link` returns 422 — Pydantic v2 reserved-name bug on the backend; the Sources tab surfaces the error to the user
- **Integration smoke test pattern:** `test/integration_smoke.dart` hits all endpoints and parses each response with the model's `fromJson`. Run it as `dart run test/integration_smoke.dart` (the script self-imports `../lib/models/*.dart`). Add it to `analysis_options.yaml`'s `analyzer.exclude` block so `flutter analyze` stays clean — the file uses `print` and relative lib imports intentionally. This is the fastest way to catch upstream schema drift before a UI bug report.
- **Docs under `docs/`:** the project ships with `README.md` + `docs/README.md` + `docs/architecture/*` + `docs/api/*` + `docs/operations/*`. Mirror this for any future Kodmoz subdomain app — it pays for itself the first time someone else picks up the project.
- **Platforms verified on Windows host:** Android APK (debug 140MB, release 49MB), Web (`build/web/`). iOS/macOS need a Mac; Linux needs GTK; Windows needs Developer Mode.

## Pattern: integration smoke test against a live API

When the mobile app talks to a live FastAPI / similar backend, ship a
`test/integration_smoke.dart` alongside `test/widget_test.dart`. The script
hits every endpoint the app actually uses, parses the first item of each
list response through the matching model's `fromJson`, and prints a one-line
pass/fail. Exclude it from `flutter analyze` because it uses `print` and
relative `../lib/...` imports intentionally.

```dart
// test/integration_smoke.dart
import 'dart:convert';
import 'dart:io';
import '../lib/models/notebook.dart';
// …one import per model the app deserialises

Future<(int, String)> _get(String base, String ep) async {
  final r = await HttpClient().getUrl(Uri.parse('$base$ep')).then((req) {
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $PW');
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    return req.close();
  });
  return (r.statusCode, await r.transform(utf8.decoder).join());
}

void main() async {
  // for each endpoint: call _get, assert 200, decode list, parse first
  // item through fromJson, print OK/FAIL with a short summary.
}
```

Run with `dart run test/integration_smoke.dart`. Wire it into the deploy
checklist (build + analyze + test + smoke). When the upstream schema drifts,
the smoke test catches it before the UI does.

## References

- `references/agents-kodmoz-api.md` — full endpoint + JSON shape notes from the August 2026 build, including quirks like `payload` being a JSON-encoded string in events.

## Support scripts

- `scripts/verify-flutter-manifest.sh <path-to-app-release.apk>` — confirms the shipped APK's `<application android:name>` resolves to a Flutter `*Application` class (not `android.app.Application`). Run after every `flutter build apk --release`. Returns 0 on OK, 1 on FAIL. Handles the MSYS→native path conversion needed by `aapt.exe` on this Windows host.

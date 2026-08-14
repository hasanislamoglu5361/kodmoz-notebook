---
name: kodmoz-notebook-mobile
description: "Build the Kodmoz Notebook Flutter app (notebook.kodmoz.com)."
version: 1.0.0
author: Aura
license: MIT
platforms: [windows, macos, linux, android, ios, web]
metadata:
  hermes:
    tags: [flutter, mobile, kodmoz, notebook, open-notebook]
    category: devops
    related: [kodmoz-flutter-mobile, kodmoz-open-notebook-operations]
---

# Kodmoz Notebook Mobile

Build, run, debug and extend the **`kodmoz_notebook`** Flutter app — the
mobile/desktop/web client for **`notebook.kodmoz.com`** (a self-hosted
Open Notebook deployment on the Kodmoz k3s cluster).

> Source: `/home/ben/kodmoz\mobile\kodmoz_notebook\` (single Flutter codebase,
> 6 platforms). Companion docs live in `docs/` inside the project. For
> the broader Flutter-on-Kodmoz playbook see `kodmoz-flutter-mobile`.
> For the backend see `kodmoz-open-notebook-operations`.

## Trigger

- "Build the Kodmoz Notebook app", "Fix a bug in the notebook mobile
  client", "Ship a new notebook screen", "Why won't the APK launch on
  Android?", "Add Open Notebook support to mobile", "Update the docs".
- Any work touching `/home/ben/kodmoz\mobile\kodmoz_notebook\`.

## Quick start (verified on this Windows host, Aug 2026)

```bash
export PATH="/c/Program Files/PowerShell/7:/c/WINDOWS/system32:/c/Users/ben/flutter-sdk/bin:/mingw64/bin:/usr/bin:/c/Program Files/Git/cmd:$PATH"
cd /c/Kodmoz/mobile/kodmoz_notebook

# 1. Lint — must be 0 issues before shipping
flutter analyze

# 2. Unit + widget test
flutter test

# 3. Live API probe (hits the real Kodmoz Open Notebook deployment)
dart run test/integration_smoke.dart

# 4. Release APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk (~49 MB)
```

The smoke test hits `https://notebook.kodmoz.com/api` with the shared
bearer token from the k8s secret
`kubectl -n open-notebook get secret open-notebook-secrets
-o jsonpath='{.data.app-password}' | base64 -d` (= `Kodmoz!!2026!!`).

## Project shape

```
lib/
  main.dart                         # MaterialApp + dark theme + login → root shell
  api/api_client.dart               # ApiClient, bearer auth, SharedPreferences token
  models/                           # one file per resource, all with fromJson()
    notebook.dart  note.dart  source.dart
    chat_session.dart  chat_message.dart
    recently_viewed.dart  transformation.dart
    model.dart  credential.dart
  screens/                          # StatefulWidget + Future + RefreshIndicator
    login_screen.dart               # username + password → saveToken → probe
    home_screen.dart                # stat tiles + notebook list + recently viewed
    notes_screen.dart               # global notes + create/edit/delete + detail
    sources_screen.dart             # global sources + add link/text
    chat_screen.dart                # chat sessions per notebook + filter chips
    chat_session_screen.dart        # bubble UI, POST /chat/execute
    notebook_detail_screen.dart     # tabs: notes / sources / chat launcher
    settings_screen.dart            # tabs: models / credentials / transformations
  widgets/
    status_badge.dart               # status palette (ready/processing/failed/human/ai/...)
    stat_tile.dart                  # home grid tile
    format.dart                     # fmtRelative / fmtAbsolute for ISO timestamps
test/
  widget_test.dart                  # boots into splash while loading token
  integration_smoke.dart            # live probe of all 7 endpoints + fromJson
docs/
  README.md                         # reading order
  architecture/overview.md          # 3-tier system
  architecture/data-model.md        # SurrealDB tables (inferred)
  architecture/auth.md              # single-bearer model + login UX
  api/README.md                     # endpoint subset the app uses
  api/endpoints.md                  # all 95 routes, grouped by router
  api/models.md                     # all 60 Pydantic models with fields
  operations/build-and-deploy.md    # per-platform build commands
  operations/local-verified-facts.md  # 12 Aug 2026 live response shapes
  operations/known-bugs.md          # 6 bugs, workarounds, fixes
```

## API surface the app uses

| Endpoint | Where in app |
|---|---|
| `GET /auth/status` | Login probe |
| `GET/POST/PUT/DELETE /notebooks[/...]` | Home + notebook detail |
| `GET /notebooks/recently-viewed` | Home (best-effort) |
| `GET/POST/PUT/DELETE /notes[/...]` | Notes tab + detail |
| `GET/POST/DELETE /sources[/...]` | Sources tab (POST has upstream bug) |
| `GET/POST/DELETE /chat/sessions[/...]` | Chat tab |
| `POST /chat/execute` | Chat session screen |
| `GET /models` / `GET /credentials` / `GET /transformations` | Settings tabs |

The chat-sessions endpoint requires `notebook_id` (422 otherwise —
backend bug #2). The sources POST returns 422 with "type required"
(Pydantic v2 reserved-name bug, backend bug #1). Both are documented in
`docs/operations/known-bugs.md` and worked around in the UI.

## Critical things NOT to forget when extending

1. **Manifest's `<application android:name>` must be set explicitly** to
   `io.flutter.embedding.android.FlutterApplication` — do NOT rely on
   `${applicationName}` being substituted by the Flutter Gradle plugin.
   See `docs/operations/known-bugs.md` §6 for the v1.0.0 → v1.0.1 fix.
2. **MainActivity.kt's `package` declaration must match `namespace`** in
   `android/app/build.gradle.kts`. If you rename the namespace, move the
   Kotlin file too — AGP 8+ won't error but the launcher will crash.
3. **Use `SharedPreferences` for the bearer token** — the build host
   lacks Android SDK 34, so `flutter_secure_storage: ^9.2.4` fails
   (`compileSdk 34` is hardcoded). Documented in
   `kodmoz-flutter-mobile` skill.
4. **Test on a real Android phone before declaring success** — every
   `flutter analyze` clean / `flutter test` pass / release-build success
   still leaves manifest merger bugs in the APK. Always
   `aapt dump xmltree app-release.apk AndroidManifest.xml` and confirm
   `android:name` is the Flutter class.
5. **`flutter clean` re-emits "Upgrading build.gradle.kts"** which can
   silently revert custom `minSdk` values. If you pin `minSdk = 23` to
   support Android 6 phones, you must re-edit after every `flutter
   clean`.

## Known bugs and their workarounds

1. `POST /sources` 422 — Pydantic v2 reserved-name (`type`) bug. App
   surfaces error.
2. `GET /chat/sessions` requires `notebook_id` — Chat tab forces user to
   pick a notebook or shows error.
3. `flutter_secure_storage` requires Android SDK 34 — use
   `SharedPreferences`.
4. APK >45 MB → use the `send-media-to-telegram` skill's tmpfiles.org
   fallback with SHA-256 verification.
5. `POST /sources` `type` collision (same root cause as #1).
6. **App won't launch on Android (fixed in v1.0.1)** — manifest
   `applicationName` placeholder resolving to `android.app.Application`
   instead of `FlutterApplication`. See `docs/operations/known-bugs.md`.

## Where to look first

- App architecture / file layout: this skill (above).
- Live API response shapes: `docs/operations/local-verified-facts.md`.
- Endpoint catalogue: `docs/api/endpoints.md` (95 routes).
- Pydantic schema reference: `docs/api/models.md` (60 models).
- Build / deploy / install per platform:
  `docs/operations/build-and-deploy.md`.
- The 12 Aug 2026 launch failure (now fixed): see
  `docs/operations/known-bugs.md` §6.

## References

- `docs/README.md` (in-repo reading order for the whole knowledge pack)
- `docs/architecture/*` — system design
- `docs/api/*` — endpoint + model reference
- `docs/operations/*` — day-to-day ops
- Companion skills: `kodmoz-flutter-mobile`, `kodmoz-open-notebook-operations`

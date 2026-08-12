# Kodmoz Notebook Mobile

Flutter client for **`notebook.kodmoz.com`** — the self-hosted Open
Notebook deployment on the Kodmoz k3s cluster. Single codebase, ships to
Android, iOS, macOS, Linux, Windows and Web.

Built **12 August 2026** by Aura (Hasan'ın `kodmoz-flutter-mobile`
skill'ine uygun şekilde). Live-tested against the running deployment.

---

## Quick start

```bash
# Get deps
flutter pub get

# Lint + tests (must be clean before shipping)
flutter analyze
flutter test

# Live API smoke test (uses the shared bearer token baked in for dev)
dart run test/integration_smoke.dart

# Build release APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk (~50 MB)
```

Install on a connected phone:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Log in with username `kodmoz` (placeholder, anything works) and password
`Kodmoz!!2026!!`.

---

## Documentation

The Open Notebook API is documented in detail under **[`docs/`](docs/)**:

- **[docs/README.md](docs/README.md)** — start here. Reading order for the
  rest of the docs.
- **[docs/architecture/](docs/architecture/)** — three-tier system, data
  model, auth model.
- **[docs/api/](docs/api/)** — endpoint reference + Pydantic model field
  reference.
- **[docs/operations/](docs/operations/)** — build & deploy, locally
  verified facts from 12 Aug 2026, known bugs.

## For other AI agents picking this up

This repo ships three agent-facing files that mirror each other so any
agent framework (Hermes / Claude Code / Cursor / Aider / generic) can
discover the playbook without prior context:

- **[AGENTS.md](AGENTS.md)** — the canonical agent playbook. Read first.
  Lists required skills, file map, hard rules, build gate, common tasks.
- **[CLAUDE.md](CLAUDE.md)** — short twin for Claude Code users; pointer
  to AGENTS.md plus the TL;DR build gate.
- **[.cursorrules](.cursorrules)** — YAML mirror for Cursor IDE. Lists
  required skills, read order, build gate, hard rules, code style.

### Skills to load before touching this project

If you're running in an environment with the Hermes `skill_view` tool,
load these three skills **in order** before reading any code:

1. **`kodmoz-notebook-mobile`** — project-specific playbook (file map,
   API surface, manifest pitfalls, build steps).
2. **`kodmoz-flutter-mobile`** — Flutter-on-Kodmoz general rules (PATH
   issues, `flutter clean` migration, iOS bundle shipping).
3. **`kodmoz-open-notebook-operations`** — backend ops (pods, secret
   retrieval, SurrealDB queries).

After loading the skills, follow the read order in
[`docs/README.md`](docs/README.md).

### Hard rules

- **`<application android:name>` in `AndroidManifest.xml` must be**
  `io.flutter.embedding.android.FlutterApplication` **explicitly.** Never
  leave `${applicationName}` placeholder — the Flutter Gradle plugin's
  auto-substitution is not guaranteed, and `android.app.Application` will
  silently kill the engine (the v1.0.0 launch bug).
- **`MainActivity.kt`'s `package` must equal `namespace` in
  `build.gradle.kts`** (currently `com.kodmoz.notebook`).
- **No `flutter_secure_storage: ^9.2.4`** — the build host lacks
  Android SDK 34. Use `SharedPreferences`.
- **Bearer token must not be hard-coded** in `lib/`. The
  `Kodmoz!!2026!!` value only appears in `test/integration_smoke.dart`.
- **Every release build must be verified** with `aapt dump xmltree
  app-release.apk AndroidManifest.xml` — confirm `<application
  android:name="io.flutter.embedding.android.FlutterApplication">`.

For the broader Flutter-mobile-for-Kodmoz playbook (path conventions,
Android build gotchas, the `bash` shadowing workaround), see the
`kodmoz-flutter-mobile` skill in `~/.hermes/skills/devops/`.

---

## What the app does

Five bottom tabs:

| Tab | What it shows |
|---|---|
| **Home** | Notebook list + counts + recently-viewed + create notebook |
| **Notes** | Global notes list + create/edit/delete + detail view |
| **Sources** | Global sources list + add link/text + status badges |
| **Chat** | Chat sessions per notebook + filter by notebook + send message |
| **Settings** | Models, Credentials, Transformations tabs + sign out |

Notebook detail (tap any notebook on Home) opens a 3-tab page: Notes
inside that notebook, Sources attached to it, Chat launcher for new
sessions inside it.

The app does **not** yet cover: podcasts, source-level chat (SSE), search,
insights, episode/speaker profiles, model management. These are
documented in [`docs/api/README.md`](docs/api/README.md) as "deliberately
not used" so the next iteration knows what's available.

---

## Architecture

```
lib/
  main.dart                     # MaterialApp + dark theme + login → root shell
  api/api_client.dart           # one ApiClient, Bearer header, SharedPreferences token
  models/                       # one file per resource, all fromJson()
    notebook.dart
    note.dart
    source.dart
    chat_session.dart
    chat_message.dart
    recently_viewed.dart
    transformation.dart
    model.dart
    credential.dart
  screens/                      # StatefulWidget + Future + RefreshIndicator
    login_screen.dart           # username + password → saveToken → probe
    home_screen.dart            # stat tiles + notebook list + recently viewed
    notes_screen.dart           # global notes + create/edit/delete
    sources_screen.dart         # global sources + add link/text
    chat_screen.dart            # chat sessions per notebook
    chat_session_screen.dart    # bubble UI, POST /chat/execute
    notebook_detail_screen.dart # tabs: notes / sources / chat launcher
    settings_screen.dart        # tabs: models / credentials / transformations
  widgets/
    status_badge.dart           # status colour palette (ready/processing/failed/human/ai/...)
    stat_tile.dart              # home grid tiles
    format.dart                 # fmtRelative / fmtAbsolute
test/
  widget_test.dart              # boots into splash
  integration_smoke.dart        # live API probe of all 7 endpoints + model fromJson
```

Conventions (from `kodmoz_agents` mobile app):

- Material 3 dark, `colorSchemeSeed: 0xFF2563EB`,
  `scaffoldBackgroundColor: 0xFF0F1115`.
- One `ApiClient` per app, owned by `_RootShell`, passed into screens as
  `widget.api`.
- `IndexedStack + KeyedSubtree` keeps each tab's scroll / future state
  alive across switches.
- AppBar refresh button rebuilds every tab by changing the key.

---

## Platforms

| Platform | Status | How |
|---|---|---|
| Android | ✓ verified | `flutter build apk --release` |
| Web (Chrome/Edge) | ✓ verified | `flutter build web --release` |
| iOS | scaffolded | needs macOS + Xcode + `pod install` |
| macOS | scaffolded | needs macOS |
| Linux | scaffolded | needs GTK dev headers |
| Windows | blocked | needs Developer Mode enabled in Windows Settings |

Verified on this Windows host:
- `flutter analyze` → **0 issues**
- `flutter test` → **1/1 pass**
- `dart run test/integration_smoke.dart` → **7/7 endpoints parse real
  API responses (ALL OK)**
- `flutter build apk --release` → **49.1 MB APK**, signed with debug keys
- `flutter build web --release` → `build/web/` ready to serve

---

## Known issues

Full list with workarounds in
[`docs/operations/known-bugs.md`](docs/operations/known-bugs.md). The two
that actually affect app users:

1. **Adding a link source returns 422** — backend bug. Pydantic v2
   rejects the `type` field. Workaround: file upstream or rename the
   field server-side. The app surfaces the error gracefully.
2. **`flutter_secure_storage` requires Android SDK 34** which isn't on
   the build host — we use plain `SharedPreferences` instead. Fine for
   single-operator; swap to `flutter_secure_storage` once Android SDK 34
   is installed.

---

## Where the bearer token lives

- Server side: `kubectl -n open-notebook get secret open-notebook-secrets
  -o jsonpath='{.data.app-password}' | base64 -d`
- Client side: typed in the login screen, stored in `SharedPreferences`,
  attached to every request via `ApiClient._headers()`.

See **[docs/architecture/auth.md](docs/architecture/auth.md)** for the
full rationale and the Cloudflare Access upgrade path.

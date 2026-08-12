# CLAUDE.md — Kodmoz Notebook Mobile

> This file is a Claude/Claude Code convention twin of `AGENTS.md`. Same
> content, different name, because some agent frameworks look for
> `CLAUDE.md` and others look for `AGENTS.md`. Keep both in sync.

See **[AGENTS.md](./AGENTS.md)** for the full agent playbook. The TL;DR:

1. **Load three skills first** (Hermes / Claude Code with skill tools):
   - `kodmoz-notebook-mobile` (project-specific)
   - `kodmoz-flutter-mobile` (Flutter-on-Kodmoz playbook)
   - `kodmoz-open-notebook-operations` (backend ops)

2. **Read order** for the in-repo docs:
   - `docs/README.md` → `docs/architecture/overview.md` →
     `docs/architecture/auth.md` → `docs/api/README.md` →
     `docs/operations/local-verified-facts.md` → `docs/operations/known-bugs.md`

3. **Build gate** (every release):
   ```bash
   cd /c/Kodmoz/mobile/kodmoz_notebook
   flutter analyze         # → 0 issues
   flutter test            # → 1/1
   dart run test/integration_smoke.dart   # → ALL OK
   flutter build apk --release
   "/c/Program Files/PowerShell/7/pwsh.exe" -Command \
     "& 'C:\Android\sdk\build-tools\36.0.0\aapt.exe' dump xmltree build/app/outputs/flutter-apk/app-release.apk AndroidManifest.xml"
   # → confirm <application android:name="io.flutter.embedding.android.FlutterApplication">
   ```

4. **Hard rules:**
   - Never trust `${applicationName}` placeholder; write
     `io.flutter.embedding.android.FlutterApplication` explicitly.
   - Never use `flutter_secure_storage: ^9.2.4`; this host lacks SDK 34.
   - Never ship an APK without inspecting the merged manifest.
   - Never bypass the bearer-token login flow for "convenience".

5. **Files you'll touch most:**
   - `lib/api/api_client.dart` — every endpoint the app uses
   - `lib/models/*.dart` — one per resource
   - `lib/screens/*.dart` — UI lives here
   - `android/app/src/main/AndroidManifest.xml` — has the FlutterApplication
     name that *must* stay explicit
   - `android/app/src/main/kotlin/com/kodmoz/notebook/MainActivity.kt` —
     package must match `namespace` in `build.gradle.kts`

6. **Where the bearer token lives:**
   - Kubernetes: `kubectl -n open-notebook get secret open-notebook-secrets -o jsonpath='{.data.app-password}' | base64 -d` → `Kodmoz!!2026!!`
   - In the app: typed in the login screen, stored in `SharedPreferences`
     under key `kodmoz_notebook_bearer_token`.

When in doubt, open `docs/operations/known-bugs.md` — every bug we've
hit so far is documented there with a workaround or fix.

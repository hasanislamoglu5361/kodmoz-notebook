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
   # → confirm <application android:name="com.kodmoz.notebook.KodmozApplication">

   # Emulator smoke test (TestAvd, API 35) — must NOT see AndroidRuntime FATAL
   flutter emulators --launch TestAvd
   "/c/Program Files/PowerShell/7/pwsh.exe" -Command "
     \$ADB='C:\Android\sdk\platform-tools\adb.exe'
     & \$ADB -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
     & \$ADB -s emulator-5554 logcat -c
     & \$ADB -s emulator-5554 shell am start -W -n com.kodmoz.notebook/com.kodmoz.notebook.MainActivity
     Start-Sleep -Seconds 5
     & \$ADB -s emulator-5554 shell pidof com.kodmoz.notebook   # non-empty = alive
     & \$ADB -s emulator-5554 logcat -d | Select-String 'AndroidRuntime|FATAL'  # empty = no crash
   "
   ```

4. **Hard rules:**
   - **`<application android:name>` in `AndroidManifest.xml` must point
     to a project-local subclass** — currently
     `com.kodmoz.notebook.KodmozApplication`, which extends
     `io.flutter.app.FlutterApplication`. Never use
     `${applicationName}` placeholder (AGP merger drops to
     `android.app.Application` — v1.0.0 bug), or raw
     `io.flutter.embedding.android.FlutterApplication` (does not exist
     in the engine — R8 strips it → ClassNotFoundException, v1.0.1 bug).
     See `docs/operations/known-bugs.md` §6 and §7.
   - **`MainActivity.kt`'s `package` must equal `namespace` in
     `build.gradle.kts`** (currently `com.kodmoz.notebook`).
   - **No `flutter_secure_storage: ^9.2.4`**; this host lacks SDK 34.
   - **Bearer token must not be hard-coded** in `lib/`. The
     `Kodmoz!!2026!!` value only appears in `test/integration_smoke.dart`.
   - **Ship APK through `send.kodmoz.com` first**; tmpfiles.org only when
     send is broken. See `~/.hermes/skills/devops/send-kodmoz-file-upload`.

5. **Files you'll touch most:**
   - `lib/api/api_client.dart` — every endpoint the app uses
   - `lib/models/*.dart` — one per resource
   - `lib/screens/*.dart` — UI lives here
   - `android/app/src/main/AndroidManifest.xml` — has
     `android:name=".KodmozApplication"` (project-local subclass)
   - `android/app/src/main/kotlin/com/kodmoz/notebook/MainActivity.kt` —
     package must match `namespace` in `build.gradle.kts`
   - `android/app/src/main/kotlin/com/kodmoz/notebook/KodmozApplication.kt`
     — the Application class the manifest references (extends
     `io.flutter.app.FlutterApplication`)

6. **Where the bearer token lives:**
   - Kubernetes: `kubectl -n open-notebook get secret open-notebook-secrets -o jsonpath='{.data.app-password}' | base64 -d` → `Kodmoz!!2026!!`
   - In the app: typed in the login screen, stored in `SharedPreferences`
     under key `kodmoz_notebook_bearer_token`.

When in doubt, open `docs/operations/known-bugs.md` — every bug we've
hit so far is documented there with a workaround or fix.

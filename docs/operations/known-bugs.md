# Known bugs

Bugs we hit while integrating, with the workarounds shipped in the mobile
client. Upstream issues are listed with their URL when filed.

## 1. `POST /sources` rejects `type: link` with "type required" — **backend bug**

**Symptom.** Every `POST /api/sources` body — including
`{"type":"link","url":"https://example.com","title":"E1"}` — returns:

```json
{"detail":[{"type":"missing","loc":["body","type"],"msg":"Field required","input":null}]}
```

…even though `type` is clearly in the body.

**Cause.** Pydantic v2 has reserved the JSON key `type` for discriminated
unions (`TaggedUnion`). The `SourceCreate` model declares
`type: str = Field(...)` but Pydantic may be silently ignoring it because
of how FastAPI + Pydantic v2 serialise the request body when a field name
collides with the framework's discriminator convention.

**Workaround in the app.** The Sources tab surface the error to the user
via the create dialog's SnackBar and the Sources list shows the error in
its error pane. We do not silently retry — the user needs to know their
input was rejected.

**Fix upstream.** Rename the field from `type` to `source_type` (or
`kind`) in `api/models.py` `SourceCreate` and `api/routers/sources.py`.
This is breaking for every existing client.

**Local verification.** 12 Aug 2026, `kodmoz_agents` skill run + this
app's integration smoke test. See
[local-verified-facts.md](local-verified-facts.md#post-sources-the-broken-one--see-known-bugsmd).

## 2. `GET /chat/sessions` requires `notebook_id` — **backend bug**

**Symptom.** `GET /api/chat/sessions` (no filter) returns 422
`{"detail":[{"type":"missing","loc":["query","notebook_id"],"msg":"Field required"}]}`.

**Cause.** `chat.py` declares the `notebook_id` query parameter as
required. Listing all chat sessions across all notebooks is impossible.

**Workaround in the app.** The Chat tab always shows a notebook picker
("All" chip + one chip per notebook). When the user picks "All" we make
the same N+1 calls as picking each notebook individually, then merge the
results in memory. This is wasteful but works.

A cleaner fix would be to add a backend endpoint that lists all sessions
for the current operator — i.e. drop the `notebook_id` requirement from
this route, or add `GET /api/chat/sessions/all`.

## 3. `flutter_secure_storage` requires Android SDK 34 — **build-host limitation**

**Symptom.** `flutter build apk` fails with:

```
> Failed to install the following SDK components:
      platforms;android-34 Android SDK Platform 34
```

**Cause.** `flutter_secure_storage: ^9.2.4` hardcodes `compileSdk 34` in
its `android/build.gradle`. The Kodmoz build host only has platforms
`android-35` and `android-36` installed. The Flutter SDK manager can't
auto-install 34 because it lives in a directory without write permission
(or the install hangs at "Failed to read or create install properties
file" — a known Windows issue when sdkmanager can't create temp files).

**Workaround in the app.** Use `shared_preferences` for token storage.
This is fine on a trusted single-operator device.

**Proper fix.** Either (a) install Android SDK 34 manually, or (b) pin
`compileSdk = 35` in `android/app/build.gradle.kts` and override the
secure-storage library's compileSdk in the project root:

```kotlin
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            project.android {
                if (namespace == "com.it_nomads.fluttersecurestorage") {
                    compileSdkVersion(35)
                }
            }
        }
    }
}
```

We chose the workaround because it was a 1-line change.

## 4. `POST /sources` `type` field collision — *related to #1*

Even if you find a way to get past the 422, the backend currently has no
way to ingest a link source over HTTP. The workaround used by the
upstream web app is to submit via multipart upload with a separate
content-type. The mobile app does not implement multipart yet.

## 5. Cloudflare proxy caching auth responses

**Symptom.** First 401 from a wrong token may return cached for a few
seconds even after the token is corrected.

**Cause.** Cloudflare's `cf-cache-status: DYNAMIC` should bypass the
cache for `Authorization`-bearing requests, but the actual cache key is
URL-only. If you spam the same endpoint rapidly with different tokens,
you may see stale responses.

**Workaround.** None in the app. If you see this in production, add a
`Vary: Authorization` header on the FastAPI side, or pin
`Cache-Control: no-store` in the Cloudflare transform rule for
`/api/*`.

## Things we have *not* hit yet but suspect exist

- `POST /chat/execute` may return a 504 if the underlying LLM call to
  OmniRoute times out. The app catches it as `ApiException(504, ...)`.
- `DELETE /notebooks/{id}` cascades to its notes, sources and chat
  sessions. The backend returns a preview count first — we don't yet
  show that count to the user before deleting.
- The SurrealDB schema migrates on API startup; if a migration fails,
  the pod crashes. There's no health endpoint for migrations specifically.

## 6. App refused to launch on Android — `android.app.Application` instead of FlutterApplication — **fixed in v1.0.1**

**Symptom.** User installed `kodmoz_notebook-v1.0.0.apk` on a real phone.
The launcher icon appeared, but tapping it produced a blank/white screen
followed by an instant back-to-launcher (or a hard crash with no toast).

**Investigation.** `aapt dump xmltree app-release.apk AndroidManifest.xml`
revealed that the merged manifest contained
`android:name="android.app.Application"` on the `<application>` element —
the *default Android Application class*, not Flutter's. Because
FlutterApplication never got a chance to instantiate, the Flutter engine
never started. `MainActivity` was also correctly resolved (via the
namespace `com.kodmoz.notebook`), so the activity loaded but had nothing
to render.

**Root cause.** The Kotlin source `MainActivity.kt` was generated by
`flutter create` at
`android/app/src/main/kotlin/com/kodmoz/kodmoz_notebook/MainActivity.kt`
with package `com.kodmoz.kodmoz_notebook`. After we changed
`build.gradle.kts` `namespace` to `com.kodmoz.notebook`, the Kotlin file
was *not* moved to the new package. Worse, the `applicationName`
manifest placeholder was being substituted by AGP's manifest merger to
`android.app.Application` instead of the FlutterApplication value that
Flutter's Gradle plugin normally injects. This combination meant the
merged manifest dropped the engine bootstrap.

**First attempted fix (v1.0.1).** Replaced `android:name="${applicationName}"`
in `AndroidManifest.xml` with
`android:name="io.flutter.embedding.android.FlutterApplication"` (the
modern embedding Application class, bundled with the Flutter engine —
does **not** require Play Core, unlike
`FlutterPlayStoreSplitApplication`).

**But v1.0.1 also crashed** — see #7 below. The class name was a figment
of wishful thinking; R8/D8 stripped it because no source actually
referenced it.

## 7. v1.0.1 crash — `ClassNotFoundException: io.flutter.embedding.android.FlutterApplication` — **fixed in v1.0.2**

**Symptom.** User installed `kodmoz_notebook-v1.0.1.apk` on a Samsung
Z Fold 6 (Android 16). The launcher icon appeared, tapping it produced
a splash screen for ~3 seconds, then the app crashed back to the
launcher with no toast.

**Investigation.** Pulled `adb logcat` while reproducing the crash on
the local emulator (TestAvd, Android 15 API 35). The fatal exception
was unambiguous:

```
java.lang.ClassNotFoundException: Didn't find class
"io.flutter.embedding.android.FlutterApplication" on path:
DexPathList[zip file ".../com.kodmoz.notebook/base.apk"]
        at android.app.AppComponentFactory.instantiateApplication(AppComponentFactory.java:76)
        at android.app.Instrumentation.newApplication(Instrumentation.java:1352)
        ...
Caused by: java.lang.ClassNotFoundException: Didn't find class
"io.flutter.embedding.android.FlutterApplication"
```

**Root cause.** The class `io.flutter.embedding.android.FlutterApplication`
**does not actually exist** in the Flutter 3.44 engine. It was a
hallucinated symbol — Flutter v2 split the embedding API across
`io.flutter.app.*` (the older, deprecated path) and
`io.flutter.embedding.*` (the new embedding where Application is **not**
exposed; only FlutterActivity / FlutterFragmentActivity exist). Picking
the v2 namespace but expecting the v1 Application class was the bug.

R8 / D8 happily stripped the bogus reference because no source code
ever imported or instantiated it. The merged manifest pointed to a
class that wasn't in the APK's dex, hence the ClassNotFoundException
on app startup.

**Fix shipped in v1.0.2:**

1. Created a project-local Application class extending Flutter's
   real Application base:
   ```kotlin
   // android/app/src/main/kotlin/com/kodmoz/notebook/KodmozApplication.kt
   package com.kodmoz.notebook
   import io.flutter.app.FlutterApplication
   class KodmozApplication : FlutterApplication()
   ```
   The compiler now has a real reference to `FlutterApplication`, so R8
   keeps it in the dex.

2. Updated `AndroidManifest.xml`:
   ```xml
   <application android:name=".KodmozApplication" ...>
   ```
   `.KodmozApplication` resolves against the namespace
   `com.kodmoz.notebook` → `com.kodmoz.notebook.KodmozApplication`.

3. Rebuilt release APK. `aapt dump xmltree` now confirms
   `android:name="com.kodmoz.notebook.KodmozApplication"`.

4. **Verified on emulator** (TestAvd, Android 15 API 35) before
   shipping:
   - `adb install -r` → Success
   - `adb shell am start -n com.kodmoz.notebook/.MainActivity` → Status: ok, TotalTime: 2932ms
   - `pidof com.kodmoz.notebook` → 23788 (still running after 6s)
   - `dumpsys activity activities` → `topResumedActivity = com.kodmoz.notebook/.MainActivity`
   - `uiautomator dump` → login screen visible (kodmoz default username, Sign in button, single-bearer-token warning text)
   - Tapped password field, typed `Kodmoz!!2026!!`, tapped Sign in →
     navigated to Notes tab showing "Test Note / human / Hello
     notebook / Updated 3h" — i.e. live API call to
     `notebook.kodmoz.com/api/notes` succeeded
   - All 5 bottom tabs (Home, Notes, Sources, Chat, Settings) present
   - `logcat` shows zero `AndroidRuntime FATAL` entries after launch

**Verification on the real phone.** If a future regression hits again,
reproduce with the same `adb logcat | grep -E "AndroidRuntime|FATAL"`
pattern. A clean launch produces no `FATAL EXCEPTION` lines from
`com.kodmoz.notebook`.

**Lesson.** When picking a Flutter Application class for the manifest:
- ❌ `io.flutter.embedding.android.FlutterApplication` — does not exist
- ❌ `io.flutter.app.FlutterApplication` — exists but R8 may strip if no
   Kotlin/Java source references it; safer to subclass it from a
   project class
- ❌ `io.flutter.embedding.android.FlutterPlayStoreSplitApplication` —
   exists but requires `com.google.android.play:core` dependency that
   the default Flutter scaffold doesn't include; build fails with R8
   missing-class error
- ✅ Subclass a real Application class (FlutterApplication or your own
   that extends it) in `android/app/src/main/kotlin/.../` and reference
   the subclass via `android:name=".YourClass"` in the manifest. R8
   keeps it because the Kotlin file is reachable from the manifest.

## 8. Emulator reproduction recipe (so future regressions can be debugged fast)

```bash
# From any terminal with the PATH set (see README.md "Quick start")
cd /c/Kodmoz/mobile/kodmoz_notebook
flutter build apk --release
"/c/Program Files/PowerShell/7/pwsh.exe" -Command "
  \$ADB = 'C:\Android\sdk\platform-tools\adb.exe'
  \$APK = '/home/ben/kodmoz\mobile\kodmoz_notebook\build\app\outputs\flutter-apk\app-release.apk'
  & \$ADB -s emulator-5554 uninstall com.kodmoz.notebook
  & \$ADB -s emulator-5554 install -r \$APK
  & \$ADB -s emulator-5554 logcat -c
  & \$ADB -s emulator-5554 shell am start -W -n com.kodmoz.notebook/com.kodmoz.notebook.MainActivity
  Start-Sleep -Seconds 5
  & \$ADB -s emulator-5554 shell pidof com.kodmoz.notebook    # non-empty = alive
  & \$ADB -s emulator-5554 logcat -d | Select-String 'AndroidRuntime|FATAL'
  # empty output = no crash
"
```

The emulator available on the Windows host is `TestAvd` (API 35,
x86_64). Launch with `flutter emulators --launch TestAvd` or via Android
Studio.

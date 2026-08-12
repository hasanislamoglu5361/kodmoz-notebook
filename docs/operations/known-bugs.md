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

**Fix shipped in v1.0.1** (see `kodmoz_notebook-v1.0.1.apk`):

1. Moved `MainActivity.kt` to
   `android/app/src/main/kotlin/com/kodmoz/notebook/MainActivity.kt`
   with `package com.kodmoz.notebook`.
2. Replaced `android:name="${applicationName}"` in `AndroidManifest.xml`
   with `android:name="io.flutter.embedding.android.FlutterApplication"`
   (the modern embedding Application class, bundled with the Flutter
   engine — does **not** require Play Core, unlike
   `FlutterPlayStoreSplitApplication`).
3. Rebuilt release APK. `aapt dump xmltree` now confirms the merged
   manifest has the correct application name.

**How to verify on a phone after install.** From `adb shell`:

```bash
adb shell am start -n com.kodmoz.notebook/.MainActivity
adb logcat -d | grep -iE "FlutterApplication|FlutterEngine|MainActivity" | tail -20
```

If you see `io.flutter.embedding.android.FlutterApplication` in the
logcat line for the activity launch, the engine is starting correctly.
If you only see `android.app.Application`, the v1.0.0 bug is back.

**Lesson for future Flutter apps on this Windows host.** Never leave
`android:name="${applicationName}"` in `AndroidManifest.xml` without
verifying the merged manifest. The Flutter Gradle plugin's
auto-substitution of that placeholder to `FlutterApplication` is *not*
guaranteed on every Flutter/AGP combination — check
`build/app/intermediates/merged_manifest/.../AndroidManifest.xml`
before shipping any APK.

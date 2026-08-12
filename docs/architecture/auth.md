# Auth

Open Notebook uses a **single shared bearer token** at the deployment level.
There is no per-user login, no OAuth, no JWT rotation. The token is set by
the operator in `open-notebook-secrets` and the FastAPI middleware enforces
it on every request.

## Server side

`api/middleware.py` reads `OPEN_NOTEBOOK_APP_PASSWORD` from the environment
and rejects every request whose `Authorization` header does not match it
(or does not exist). Endpoints exempt from auth: none. The middleware does
**not** accept `?token=` query params or Basic auth — only the bearer
header.

The Kodmoz deployment stores the password in Kubernetes:

```bash
kubectl -n open-notebook get secret open-notebook-secrets \
  -o jsonpath='{.data.app-password}' | base64 -d
# → Kodmoz!!2026!!
```

This is the value the Flutter app expects in the "Password" field.

## Client side

The Flutter app accepts username + password on the login screen but only
the password is used. The flow:

1. User types any username (default placeholder `kodmoz`) and the shared
   password.
2. App calls `saveToken(password)` → `SharedPreferences`.
3. App calls `GET /auth/status` with the token. If 200, login is
   considered successful.
4. App calls `GET /notebooks` to confirm; on 401 the token is cleared and
   the login screen re-shows with an error.
5. From then on, every API request in `ApiClient._headers()` adds
   `Authorization: Bearer <token>`.

## Why no per-user accounts

Open Notebook is designed for single-operator / small-team use. Adding
per-user auth would require a user table, JWT issuance, refresh tokens,
password reset, and a UI for all of it — a lot of surface area for a
self-hosted personal knowledge base. The maintainers chose a single shared
secret as the pragmatic minimum.

For a Kodmoz deployment this is fine: one operator, one device, one token.
If you ever expose `notebook.kodmoz.com` to other users, put it behind
Cloudflare Access and have CF inject a service token — the bearer model in
the app stays the same, you just stop letting humans see the password.

## Why we use `shared_preferences`, not `flutter_secure_storage`

The Kodmoz build host only has Android SDK 35 and 36 installed. The current
`flutter_secure_storage: ^9.2.4` hardcodes `compileSdk 34` in its
`build.gradle`. Without 34 installed, Gradle fails with
*"Failed to install the following SDK components: platforms;android-34"*.

The fix is one of:

1. Install Android SDK 34 on the build host (preferred for production).
2. Pin `compileSdk = 35` in `android/app/build.gradle.kts` and override the
   secure-storage library's `compileSdk` in the project root
   `build.gradle.kts` via `subprojects { afterEvaluate { ... } }`.
3. Drop `flutter_secure_storage` and store the token in plain
   `SharedPreferences` (current setup).

Option 3 is fine for a single-operator app on a trusted device. The token
is still inside the app sandbox and only readable from the same UID. If
you ship the APK to anyone else's phone, switch to option 1.

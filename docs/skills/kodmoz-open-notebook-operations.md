---
name: kodmoz-open-notebook-operations
description: "Use when configuring Open Notebook AI on Kodmoz Kubernetes."
version: 1.0.0
---

# Kodmoz Open Notebook Operations

Use for configuring or verifying Open Notebook on `notebook.kodmoz.com`, especially encrypted provider credentials, model registration, defaults, and runtime smoke tests.

## Configuration workflow

1. Confirm the `open-notebook` namespace, deployment, and public route.
2. Read the app password without printing it:
   ```bash
   PW=$(kubectl -n open-notebook get secret open-notebook-secrets -o jsonpath='{.data.app-password}' | base64 -d)
   ```
3. Call the app API from inside the pod with `Authorization: Bearer $PW`; unauthenticated `/api/*` calls return 401.
4. Query `/api/credentials` and `/api/models` before creating anything.
5. Create an `openai_compatible` credential with `base_url`, optional `endpoint_llm`, `endpoint_embedding`, `endpoint_tts`, and provider API key.
6. Test with `POST /api/credentials/{credential_id}/test`.
7. Discover with `POST /api/credentials/{credential_id}/discover`; use exact model IDs returned by the provider.
8. Register with `POST /api/credentials/{credential_id}/register-models`, using `language`, `embedding`, or `text_to_speech`.
9. Set defaults through `PUT /api/models/defaults`, preserving all existing fields.
10. Restart the deployment, wait for rollout, and re-read defaults.

## Provider routing

- LM Studio from an Open Notebook pod: `http://host.docker.internal:1234/v1`.
- OmniRoute from an Open Notebook pod: `http://omniroute.omniroute.svc.cluster.local/v1`.
- Hermes Codex credential: `OMNI_CODEX_API_KEY` in `C:/Users/ben/AppData/Local/hermes/.env`. Never print or persist the key in manifests/chat.
- Always call `/v1/models` and use exact IDs; do not infer availability from labels.

## Verification gate

Complete only when all pass: credential test; discovery; registration; defaults GET; direct chat HTTP 200; direct TTS HTTP 200 with `audio/mpeg` and non-empty MP3; deployment restart preserving defaults; public `https://notebook.kodmoz.com/notebooks` HTTP 200.

## Known-good configuration

- Embedding: LM Studio `text-embedding-bge-m3`, `openai_compatible`, `http://host.docker.internal:1234/v1`, default `text-embedding-bge-m3`.
- Chat: OmniRoute `codex/gpt-5.6-luna`, `openai_compatible`, default `codex/gpt-5.6-luna`.
- TTS: OmniRoute `minimax/speech-2.8-hd`, `openai_compatible`, default `minimax/speech-2.8-hd`.

## Pitfalls

- `host.docker.internal` is for LM Studio; OmniRoute should use Kubernetes Service DNS.
- Preserve the defaults payload when changing one field; otherwise embedding or other defaults may be cleared.
- Codex routing may expose `-low`, `-medium`, and `-high` variants; the tested base ID is `codex/gpt-5.6-luna`.
- Codex is a chat route, not automatically an audio provider. TTS must be a model that appears in `/v1/models` and passes `/v1/audio/speech`.
- **`POST /api/sources` always 422 with "type required" even when `type` is in the body** — Pydantic v2 reserved-name bug on the backend. Workaround in any client: surface the 422 to the user; upstream fix is to rename `type` → `source_type` in `SourceCreate` (breaking).
- **`GET /api/chat/sessions` requires `notebook_id`** — returns 422 without it. To list "all sessions" you must either call per-notebook and merge, or push for a backend endpoint that drops the requirement.

## API surface (consumer reference)

Open Notebook is a FastAPI app with **95 routes** across 22 routers. For
clients (mobile, web, CLI) talking to the live deployment:

- **Auth:** single bearer token, set by `OPEN_NOTEBOOK_APP_PASSWORD`. No
  per-user auth, no JWT rotation. Send `Authorization: Bearer <pw>` on
  every request or get 401.
- **Base URL on Kodmoz:** `https://notebook.kodmoz.com/api`
- **Backend namespace:** `open-notebook`; pods `open-notebook-*` (FastAPI +
  surreal-commands worker) and `surrealdb-*` (SurrealDB).
- **Surreal-commands worker is required for async jobs** — podcasts,
  embedding rebuild, and source processing queue silently forever if the
  worker is down. The Kodmoz deployment runs it as a sidecar in the same
  `Deployment` as FastAPI.
- **No global response envelope.** Every endpoint returns a JSON object,
  array, or `{"detail": ...}` for errors. Pydantic 422 has
  `detail: [{type, loc, msg}]` shape.
- **IDs** are SurrealDB record ids like `notebook:2dyhmmcj525amtb69g8n` —
  keep the prefix; never parse the suffix.
- **Timestamps** are ISO 8601 with timezone offset (`+00:00` on Kodmoz).
- **Counts are denormalised** — `NotebookResponse.source_count` /
  `note_count` are computed on read, not stored.

Router inventory (one file per resource family under
`open_notebook/api/routers/`):

| Router | Routes | Used by mobile |
|---|---|---|
| auth | 1 (`GET /auth/status`) | ✓ |
| notebooks | 8 | ✓ |
| notes | 5 | ✓ |
| sources | 11 | ✓ (POST blocked — see pitfalls) |
| chat | 6 | ✓ |
| models | 11 | ✓ (read-only) |
| credentials | 11 | ✓ (read-only) |
| transformations | 6 | ✓ (read-only) |
| commands | 5 | — |
| config | 1 | — |
| embedding | 1 | — |
| embedding_rebuild | 2 | — |
| episode_profiles | 5 | — |
| insights | 3 | — |
| languages | 1 | — |
| podcasts | 6 | — |
| search | 3 | — |
| settings | 2 | — |
| source_chat | 1 (SSE) | — |
| speaker_profiles | 5 | — |

Full route-by-route table: [`references/api-endpoints.md`](references/api-endpoints.md)
Full Pydantic model field reference: [`references/api-models.md`](references/api-models.md)
Live response shapes from 12 Aug 2026: [`references/api-live-facts.md`](references/api-live-facts.md)
Upstream code mirror used to build these:
[`C:\Users\ben\onb-api\src\open-notebook-main\`](C:/Users/ben/onb-api/src/open-notebook-main)

## Building a client that talks to this API

For a single-operator self-hosted app, the token model is fine. For a
mobile app the storage question matters:

- **`flutter_secure_storage: ^9.2.4` hardcodes `compileSdk 34`** — if the
  build host only has Android SDK 35/36 installed (Kodmoz's case),
  `flutter build apk` fails with `Failed to install the following SDK
  components: platforms;android-34`. The Windows sdkmanager frequently
  hangs at *"Failed to read or create install properties file"* when
  trying to auto-install 34, so manual install is the realistic path.
- **Workaround:** store the bearer token in `shared_preferences` instead.
  Acceptable on a single-operator trusted device; swap to
  `flutter_secure_storage` once SDK 34 is installed or override the
  library's compileSdk via `subprojects { afterEvaluate { ... } }` in
  the project root `build.gradle.kts`.

The Kodmoz Notebook mobile client at `/home/ben/kodmoz\mobile\kodmoz_notebook\`
uses this pattern and ships release APKs end-to-end.

See `references/open-notebook-ai-models.md` for tested API payloads and runtime evidence.

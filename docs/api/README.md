# API reference

Base URL: `https://notebook.kodmoz.com/api`

All endpoints require `Authorization: Bearer <OPEN_NOTEBOOK_APP_PASSWORD>`.
The token is the value from the `open-notebook-secrets` Kubernetes secret in
the `open-notebook` namespace.

- **Full route inventory:** [`endpoints.md`](endpoints.md) — every route
  we found in the upstream source, grouped by router file.
- **Full Pydantic model inventory:** [`models.md`](models.md) — every
  request and response model with field types.

## Endpoints the mobile app uses

The Flutter client touches a subset of the 95 upstream routes. The rest are
either internal admin endpoints (e.g. `/commands/registry/debug`,
`/embedding/rebuild/*`) or feature surfaces the mobile app does not yet
implement (podcasts, source-level chat, episode/speaker profiles, model
management).

| Endpoint | App surface | Notes |
|---|---|---|
| `GET /auth/status` | Login probe | Optional; the app falls back to a notebook probe. |
| `GET /notebooks` | Home, NotebookDetail | Supports `archived` and `order_by` query params. |
| `POST /notebooks` | Home (New) | Body: `{name, description?}`. |
| `DELETE /notebooks/{id}` | Home long-press | Backend returns a preview count of items that will be deleted. |
| `PUT /notebooks/{id}` | Notebook detail (rename/archive) | |
| `GET /notebooks/recently-viewed` | Home | Best-effort; failure is silent. |
| `GET /notes` | Notes tab | Supports `notebook_id` filter. |
| `POST /notes` | Notes tab (New) | Body: `{title, content, note_type}`. |
| `GET /notes/{id}` | Note detail | |
| `PUT /notes/{id}` | Note detail (Edit) | |
| `DELETE /notes/{id}` | Note detail | |
| `GET /sources` | Sources tab | The app filters in-memory by `notebook_ids`. |
| `POST /sources` | Sources tab (Add) | **Has the Pydantic-v2 reserved-name bug — see known-bugs.md.** |
| `DELETE /sources/{id}` | (not wired in v1) | |
| `GET /chat/sessions` | Chat tab | **Requires `notebook_id` — 422 otherwise.** |
| `POST /chat/sessions` | Chat tab (New) | Body: `{notebook_id, title?, model_override?}`. |
| `DELETE /chat/sessions/{id}` | (not wired in v1) | |
| `POST /chat/execute` | Chat session screen | Body: `{session_id, message, context, model_override?}`. |
| `GET /models` | Settings → Models tab | |
| `GET /credentials` | Settings → Credentials tab | Returns a list — `api_key` is never exposed. |
| `GET /transformations` | Settings → Transformations tab | Expansion tile shows full prompt. |

## Endpoints deliberately not used

These exist in the API and are documented in `endpoints.md`, but the
mobile app does not call them. They are listed here so future iterations
of the app know what's available without re-reading the upstream source.

- **Source-level chat (`POST /sources/{id}/chat/sessions/.../messages`)** —
  SSE streaming chat scoped to one source. The mobile app currently uses
  notebook-level chat only.
- **Podcasts (`/podcasts/generate`, `/podcasts/episodes`, …)** — async TTS
  job queue. Not implemented in mobile yet.
- **Search (`POST /search`, `/search/ask`)** — vector + BM25 + LLM. The
  mobile app does not expose search yet.
- **Insights (`/insights/{id}/save-as-note`)** — promoted-from-source
  insights. Not implemented in mobile yet.
- **Episode/Speaker profiles** — podcast configuration. Not implemented.
- **Model management (`/models`, `/models/defaults`, `/models/auto-assign`)** —
  the mobile app only reads models; creating/updating is web-admin only.
- **Embedding rebuild (`/rebuild`, `/rebuild/{id}/status`)** — operator
  endpoint, async job.
- **Migrations (`/credentials/migrate-from-env`,
  `/credentials/migrate-from-provider-config`)** — one-shot operator
  helpers.

## Response envelope

There is no global envelope. Every endpoint returns either:

- A JSON object (single entity, e.g. `GET /notebooks/{id}`).
- A JSON array (collection, e.g. `GET /notebooks`).
- HTTP 204 with empty body for some deletes.
- HTTP 401 with `{"detail": "..."}` on bad/missing bearer.
- HTTP 422 with a Pydantic validation error: `{"detail": [{"type": ..., "loc": [...], "msg": ...}, ...]}`
  — see `ApiException.displayMessage` in `lib/api/api_client.dart` for how
  the app formats these.

## Timeouts

The Flutter client sets a 20-second timeout on every request. If a slow
endpoint (e.g. a notebook with thousands of sources) is added later,
bump the timeout in `ApiClient._request`.

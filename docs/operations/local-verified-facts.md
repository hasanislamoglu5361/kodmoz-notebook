# Local verified facts

Everything in this file was observed on **12 August 2026** by running
`curl` against `https://notebook.kodmoz.com/api` from this Windows host
with the live bearer token. If a fact here disagrees with
[`../api/endpoints.md`](../api/endpoints.md) or `../api/models.md`, the
upstream Pydantic model wins — these are facts *about the live deployment*
that may differ from the source code (e.g. due to model migrations not
yet merged upstream).

## Deployment

- Namespace: `open-notebook`
- Pods:
  - `open-notebook-6bc8849db9-jmwvs` — FastAPI + surreal-commands worker
  - `surrealdb-74545584db-qjn5x` — SurrealDB
- Container image: `lfnovo/open_notebook:v1-latest`
- Auth: single bearer token in `secret/open-notebook-secrets`, key
  `app-password`. Value: `Kodmoz!!2026!!`.
- Public route: `https://notebook.kodmoz.com` (Cloudflare proxy, HSTS).
- API root: `https://notebook.kodmoz.com/api`

## Live response shapes

### `GET /notebooks`

```json
[{"id":"notebook:2dyhmmcj525amtb69g8n","name":"Test NB","description":"smoke test","archived":false,"created":"2026-08-12 05:55:05.570640+00:00","updated":"2026-08-12 06:16:26.141429+00:00","source_count":0,"note_count":0}]
```

### `POST /notebooks`

Body: `{"name":"Test NB","description":"smoke test"}`

Response: 200 with the full `NotebookResponse` (same as GET). No `Location`
header.

### `GET /notes`

Empty list when no notes exist. Once a note is created:

```json
[{"id":"note:m06t1zc6w8ztirsojiq5","title":"Test Note","content":"Hello notebook","note_type":"human","created":"2026-08-12 06:16:26.889433+00:00","updated":"2026-08-12 06:16:26.889440+00:00","command_id":"command:f8sfgropguwuu8uw1yw9"}]
```

Note the extra `command_id` field — not in the upstream `NoteResponse`
model. The mobile app ignores unknown fields, so this is harmless. It
indicates the create kicked off a background command (probably embedding).

### `POST /notes`

Body: `{"title":"Test Note","content":"Hello notebook","note_type":"human"}`

Response: 200, includes `command_id` of the async embed job.

### `GET /sources`

Empty list. Sources only appear after one is created and processed.

### `POST /sources` (the broken one — see known-bugs.md)

Always returns 422 with `{"detail":[{"type":"missing","loc":["body","type"],"msg":"Field required","input":null}]}` —
even when `type` is in the JSON body. See [known-bugs.md](known-bugs.md)
for the workaround.

### `POST /chat/sessions`

Body: `{"notebook_id":"notebook:2dyhmmcj525amtb69g8n","title":"Test session"}`

Response: 200 with `ChatSessionResponse`:

```json
{"id":"chat_session:i6rpvd3x5es34sr6hkfx","title":"Test session","notebook_id":"notebook:2dyhmmcj525amtb69g8n","created":"2026-08-12 06:20:10.648600+00:00","updated":"2026-08-12 06:20:10.648601+00:00","message_count":0,"model_override":null}
```

### `GET /chat/sessions?notebook_id=...`

Returns 200 with the array. **`GET /chat/sessions` with no filter
returns 422** — confirmed.

### `GET /models`

```json
[{"id":"model:2i8ac6cjaffcj8z4sn12","name":"codex/gpt-5.6-luna","provider":"openai_compatible","type":"language","credential":"credential:d5y2de4qg6tlmty9zf0g","created":"2026-08-12 01:53:54.487325+00:00","updated":"2026-08-12 01:53:54.487326+00:00"}, ...]
```

### `GET /credentials`

Returns the list with `has_api_key: true/false` and `modalities`. The
`api_key` itself is **never** returned (encrypted server-side).

### `GET /transformations`

The seeded "Paper Analysis" transformation is present and its prompt is
~2200 characters long. The full text is visible in
[api/models.md `TransformationResponse`](../api/models.md#transformationresponse).

### `GET /settings`

```json
{"default_content_processing_engine_doc":"auto","default_content_processing_engine_url":"auto","default_embedding_option":"ask","auto_delete_files":"yes","docling_ocr":true,"docling_formulas":false,"docling_vision":false,"youtube_preferred_languages":["en","pt","es","de","nl","en-GB","fr","de","hi","ja"]}
```

### `GET /notebooks/recently-viewed`

Empty list when no items have been viewed. The endpoint *exists* (200 OK)
but is best-effort — failure is non-fatal in the app.

## Status codes observed

| Code | Meaning | Where |
|---|---|---|
| 200 | OK | All happy paths |
| 401 | Missing/invalid bearer | No `Authorization` header, wrong token |
| 404 | Unknown route | Hitting non-existent paths |
| 422 | Validation error | Pydantic rejected the body — most common on `POST /sources` |
| 500 | SurrealDB error | Rare; backend bug |

## Performance

- All endpoints respond in **< 200 ms** with a warm DB cache.
- `POST /chat/execute` is the only endpoint that can take several seconds
  — it invokes LangGraph + a remote LLM. The mobile app has a 20-second
  timeout on every call; bump it if you see `ApiException` timeouts in
  the chat screen.

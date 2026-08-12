# Data model

Open Notebook persists everything in SurrealDB. The API never exposes table
names directly — every response wraps a row in a Pydantic response model.
This page describes the conceptual shapes so the Flutter app's models make
sense.

> The Pydantic definitions are the source of truth for wire format; see
> [`api/models.md`](../api/models.md). The SurrealDB tables listed here are
> inferred from the API and the domain layer
> (`open_notebook/domain/notebook.py` etc.) — they are not directly exposed.

## Entities

| Entity | SurrealDB table (inferred) | Notes |
|---|---|---|
| Notebook | `notebook` | Top-level container. Holds N sources + N notes + N chat sessions. Soft-delete via `archived: bool`. |
| Source | `source` | A URL, an uploaded file, or a raw text snippet. Async-processed into chunks + embeddings. May belong to many notebooks (many-to-many through `reference`). |
| Note | `note` | Human-authored (`note_type: "human"`) or AI-generated (`note_type: "ai"`). Independent of notebooks except via references. |
| ChatSession | `chat_session` | A conversation about a specific notebook. Messages live inside the session. |
| Transformation | `transformation` | Reusable prompt template (e.g. "Analyze Paper"). Applied to sources or run standalone. |
| Model | `model` | A registered LLM / embedding / TTS model, linked to a credential. |
| Credential | `credential` (encrypted) | A provider credential + base URL + endpoints. API key is encrypted at rest with `OPEN_NOTEBOOK_ENCRYPTION_KEY`. |
| Insight | `insight` | AI-extracted nuggets from a source. Can be promoted to a note. |
| EpisodeProfile | `episode_profile` | Template for podcast episodes (length, format, focus). |
| SpeakerProfile | `speaker_profile` | TTS voice config for podcast hosts. |
| PodcastEpisode | `podcast_episode` | Generated audio. Async job. |
| Setting | `setting` | Singleton config blob (`default_embedding_option`, `youtube_preferred_languages`, …). |

## Field type conventions

The Pydantic models use a small set of types. Translating to Dart:

| Pydantic | Dart |
|---|---|
| `str` | `String` (always nullable when `Optional[str]`) |
| `int` / `float` | `int` / `double` |
| `bool` | `bool` |
| `List[T]` | `List<T>` (always growable: false when reading, except where we add) |
| `Optional[X]` | `X?` |
| `Literal["a", "b"]` | Dart `enum` or `String` with allowed set |
| `datetime` rendered as ISO string | `String` (UTC, e.g. `2026-08-12 05:55:05.570640+00:00`) — we display relative via `fmtRelative` |
| SurrealDB record id `notebook:abc123` | `String` — keep the prefix; `cleanId` strips it for display |

## ID format

Every entity has a SurrealDB record id like `notebook:2dyhmmcj525amtb69g8n`.
The mobile app keeps the full string and only strips the prefix for
display. **Do not** parse the id's suffix — SurrealDB generates them and
they are opaque.

## Timestamps

All timestamps come back as SurrealDB `time` values, serialised as ISO 8601
strings with timezone offset. The Kodmoz deployment uses `+00:00`. Example:

```
2026-08-12 05:55:05.570640+00:00
```

The app does not parse these for arithmetic — only for display via
`fmtRelative` ("3h ago") and `fmtAbsolute` ("2026-08-12 06:16"). If you need
durations, parse them in your own code with `DateTime.parse`.

## Counts are denormalised

`NotebookResponse` includes `source_count` and `note_count`. The backend
computes these on read — they are **not** stored on the notebook row. The
mobile app reads them as plain integers and renders them in the home screen
grid. Treat them as eventually consistent: refreshing the home screen
after adding a source may briefly show the old count.

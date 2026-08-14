# API endpoints

Every route we found in the upstream `open_notebook/api/routers/` directory. Routes the mobile app actively calls are marked ✓ in the **Used by app** column; routes marked — are documented for future use but not called from the Flutter client yet.

> Counted: **95 routes across 20 routers.** Generated from `api/_index.json` which is the canonical mirror of the upstream Python sources on 12 August 2026.

## `auth.py` ✓

| Method | Path |
|---|---|
| `GET` | `/auth/status` |

## `chat.py` ✓

| Method | Path |
|---|---|
| `GET` | `/chat/sessions` |
| `POST` | `/chat/sessions` |
| `PUT` | `/chat/sessions/{session_id}` |
| `DELETE` | `/chat/sessions/{session_id}` |
| `POST` | `/chat/execute` |
| `POST` | `/chat/context` |

## `commands.py` —

| Method | Path |
|---|---|
| `POST` | `/commands/jobs` |
| `GET` | `/commands/jobs/{job_id}` |
| `GET` | `/commands/jobs` |
| `DELETE` | `/commands/jobs/{job_id}` |
| `GET` | `/commands/registry/debug` |

## `config.py` —

| Method | Path |
|---|---|
| `GET` | `/config` |

## `credentials.py` ✓

| Method | Path |
|---|---|
| `GET` | `/credentials/status` |
| `GET` | `/credentials/env-status` |
| `GET` | `/credentials/by-provider/{provider}` |
| `GET` | `/credentials/{credential_id}` |
| `PUT` | `/credentials/{credential_id}` |
| `DELETE` | `/credentials/{credential_id}` |
| `POST` | `/credentials/{credential_id}/test` |
| `POST` | `/credentials/{credential_id}/discover` |
| `POST` | `/credentials/{credential_id}/register-models` |
| `POST` | `/credentials/migrate-from-provider-config` |
| `POST` | `/credentials/migrate-from-env` |

## `embedding.py` —

| Method | Path |
|---|---|
| `POST` | `/embed` |

## `embedding_rebuild.py` —

| Method | Path |
|---|---|
| `POST` | `/rebuild` |
| `GET` | `/rebuild/{command_id}/status` |

## `episode_profiles.py` —

| Method | Path |
|---|---|
| `GET` | `/episode-profiles` |
| `GET` | `/episode-profiles/{profile_name}` |
| `POST` | `/episode-profiles` |
| `PUT` | `/episode-profiles/{profile_id}` |
| `DELETE` | `/episode-profiles/{profile_id}` |

## `insights.py` —

| Method | Path |
|---|---|
| `GET` | `/insights/{insight_id}` |
| `DELETE` | `/insights/{insight_id}` |
| `POST` | `/insights/{insight_id}/save-as-note` |

## `languages.py` —

| Method | Path |
|---|---|
| `GET` | `/languages` |

## `models.py` ✓

| Method | Path |
|---|---|
| `GET` | `/models` |
| `POST` | `/models` |
| `DELETE` | `/models/{model_id}` |
| `POST` | `/models/{model_id}/test` |
| `GET` | `/models/defaults` |
| `PUT` | `/models/defaults` |
| `GET` | `/models/providers` |
| `POST` | `/models/sync/{provider}` |
| `POST` | `/models/sync` |
| `GET` | `/models/count/{provider}` |
| `GET` | `/models/by-provider/{provider}` |
| `POST` | `/models/auto-assign` |

## `notebooks.py` ✓

| Method | Path |
|---|---|
| `GET` | `/notebooks` |
| `POST` | `/notebooks` |
| `GET` | `/recently-viewed` |
| `GET` | `/notebooks/{notebook_id}` |
| `PUT` | `/notebooks/{notebook_id}` |
| `POST` | `/notebooks/{notebook_id}/sources/{source_id}` |
| `DELETE` | `/notebooks/{notebook_id}/sources/{source_id}` |
| `DELETE` | `/notebooks/{notebook_id}` |

## `notes.py` ✓

| Method | Path |
|---|---|
| `GET` | `/notes` |
| `POST` | `/notes` |
| `GET` | `/notes/{note_id}` |
| `PUT` | `/notes/{note_id}` |
| `DELETE` | `/notes/{note_id}` |

## `podcasts.py` —

| Method | Path |
|---|---|
| `POST` | `/podcasts/generate` |
| `GET` | `/podcasts/jobs/{job_id}` |
| `GET` | `/podcasts/episodes` |
| `GET` | `/podcasts/episodes/{episode_id}` |
| `GET` | `/podcasts/episodes/{episode_id}/audio` |
| `POST` | `/podcasts/episodes/{episode_id}/retry` |
| `DELETE` | `/podcasts/episodes/{episode_id}` |

## `search.py` —

| Method | Path |
|---|---|
| `POST` | `/search` |
| `POST` | `/search/ask` |
| `POST` | `/search/ask/simple` |

## `settings.py` —

| Method | Path |
|---|---|
| `GET` | `/settings` |
| `PUT` | `/settings` |

## `source_chat.py` —

| Method | Path |
|---|---|
| `POST` | `/sources/{source_id}/chat/sessions/{session_id}/messages` |

## `sources.py` ✓

| Method | Path |
|---|---|
| `GET` | `/sources` |
| `POST` | `/sources` |
| `POST` | `/sources/json` |
| `GET` | `/sources/{source_id}` |
| `GET` | `/sources/{source_id}/download` |
| `GET` | `/sources/{source_id}/status` |
| `PUT` | `/sources/{source_id}` |
| `POST` | `/sources/{source_id}/retry` |
| `DELETE` | `/sources/{source_id}` |
| `GET` | `/sources/{source_id}/insights` |

## `speaker_profiles.py` —

| Method | Path |
|---|---|
| `GET` | `/speaker-profiles` |
| `GET` | `/speaker-profiles/{profile_name}` |
| `POST` | `/speaker-profiles` |
| `PUT` | `/speaker-profiles/{profile_id}` |
| `DELETE` | `/speaker-profiles/{profile_id}` |

## `transformations.py` ✓

| Method | Path |
|---|---|
| `GET` | `/transformations` |
| `POST` | `/transformations` |
| `POST` | `/transformations/execute` |
| `GET` | `/transformations/default-prompt` |
| `PUT` | `/transformations/default-prompt` |
| `DELETE` | `/transformations/{transformation_id}` |

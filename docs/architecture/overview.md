# Architecture overview

Open Notebook is a **three-tier system**. The mobile app sits outside the
cluster and talks only to the middle tier.

```
┌─────────────────────────────────────┐
│  Flutter mobile / web / desktop     │  ← this app
│  (Android, iOS, macOS, Linux,       │
│   Windows, Web — single codebase)   │
└────────────────┬────────────────────┘
                 │ HTTPS + Bearer
                 ▼
┌─────────────────────────────────────┐
│  FastAPI    port 5055               │  ← open-notebook pod
│  • Auth middleware (single bearer)  │
│  • 95 REST routes                   │
│  • LangGraph chat & transforms      │
│  • Pydantic v2 request/response     │
└────────────────┬────────────────────┘
                 │ surreal_commands (async job bus)
                 ▼
┌─────────────────────────────────────┐
│  SurrealDB   port 8000              │  ← surreal pod
│  • Document + vector + graph        │
│  • BM25 full-text search            │
│  • Schema migrations on API start   │
└────────────────┬────────────────────┘
                 │
                 ▼
       Background workers (surreal-commands)
       • podcast generation (TTS)
       • embedding rebuild
       • source ingestion & chunking
```

## Why three tiers and not one

- **SurrealDB alone is not enough** — it doesn't host a public HTTP API.
- **FastAPI alone is not enough** — it doesn't persist async jobs (podcast
  generation, embedding rebuild, source processing). Those run on the
  surreal-commands worker queue that ships with Open Notebook.
- The Next.js frontend in upstream is **not** how Kodmoz exposes the system
  — we hit the FastAPI API directly. This makes the mobile client
  significantly simpler than the upstream web app: no SSE proxy, no
  client-side store, just HTTP + JSON.

## Surreal-commands workers

Podcasts, embeddings and source processing are *async*. The FastAPI process
submits a job to surreal-commands; the worker pod picks it up, runs the
job, and writes the result back to SurrealDB. Without the worker running:

- `/api/sources` POSTs queue silently forever
- `/api/embedding/rebuild` does nothing
- `/api/podcasts/generate` returns a job id that never resolves

The Kodmoz deployment runs the worker as a sidecar in the same `Deployment`
as the FastAPI process — see `operations/build-and-deploy.md` for how to
verify it is up.

## File map of the upstream Python package (mirrored locally)

The raw source we used to write the API docs lives at
`C:\Users\ben\onb-api\src\open-notebook-main\`. The relevant slice:

```
open_notebook/
  api/
    main.py            # FastAPI app, middleware, lifespan
    middleware.py      # bearer-token auth middleware
    models.py          # 60 Pydantic v2 request/response models
    routers/           # one file per resource family
      auth.py          # /auth/status
      chat.py          # /chat/sessions, /chat/execute, /chat/context
      commands.py      # /commands/jobs (job inspection)
      credentials.py   # /credentials/* (provider credentials)
      embedding.py     # /embed
      embedding_rebuild.py
      episode_profiles.py
      insights.py
      languages.py
      models.py        # /models/*
      notebooks.py     # /notebooks/*
      notes.py         # /notes/*
      podcasts.py      # /podcasts/* (async generation)
      search.py        # /search, /search/ask
      settings.py      # /settings
      source_chat.py   # SSE source-level chat
      sources.py       # /sources/*
      speaker_profiles.py
      transformations.py
```

Every route and model we use in the mobile app has an entry in
[`api/endpoints.md`](../api/endpoints.md) and [`api/models.md`](../api/models.md).

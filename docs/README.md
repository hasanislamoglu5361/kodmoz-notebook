# Open Notebook — Knowledge Pack

Open Notebook is the open-source AI research notebook behind
**`notebook.kodmoz.com`**. It is self-hosted on the Kodmoz k3s cluster and
exposes a REST API consumed by this Flutter app. This knowledge pack is the
reference we extracted from the upstream source code (`lfnovo/open-notebook`)
plus live probing of the running deployment, so future agents and humans can
rebuild, debug or extend the mobile client without rediscovering the API.

> **Provenance.** Everything in `docs/` was derived from two sources only:
>
> 1. The official Python source under `open_notebook/api/` — see the upstream
>    repo at <https://github.com/lfnovo/open-notebook>. We mirrored the
>    routers + models locally during the initial integration on 12 August
>    2026; the raw JSON index lives in [`api/_index.json`](api/_index.json)
>    and is the single source of truth for route counts and model field
>    names.
> 2. Live `curl` probes against `https://notebook.kodmoz.com/api` with
>    `Authorization: Bearer <kodmoz-app-password>`. Where a live response
>    disagrees with the upstream Pydantic schema, the live response wins and
>    the deviation is called out.

## Reading order

1. **[architecture/overview.md](architecture/overview.md)** — what the three
   tiers do, how they connect, where the bearer token lives.
2. **[architecture/data-model.md](architecture/data-model.md)** — the
   SurrealDB tables the API serialises to and from.
3. **[architecture/auth.md](architecture/auth.md)** — bearer token model,
   env vars, why the login screen accepts a "password".
4. **[api/README.md](api/README.md)** — entry point for the API surface.
   Read this before opening individual route files.
5. **[api/endpoints.md](api/endpoints.md)** — every HTTP route, organised by
   router file.
6. **[api/models.md](api/models.md)** — every Pydantic request/response model
   with field types and defaults.
7. **[operations/local-verified-facts.md](operations/local-verified-facts.md)**
   — what we *actually* saw on 12 August 2026: response shapes, quirks, the
   bugs the app has to work around.
8. **[operations/build-and-deploy.md](operations/build-and-deploy.md)** — how
   to build the Flutter client and ship APKs to a phone.
9. **[operations/known-bugs.md](operations/known-bugs.md)** — upstream +
   deployment bugs we hit, with workarounds shipped in the app.

## What is *not* in this pack

- The frontend (Next.js under `frontend/`) — this app talks to the API, not
  the frontend.
- The SurrealDB schema files — they live inside the upstream repo at
  `open_notebook/database/migrations/`. We rely on FastAPI to migrate the
  schema automatically on startup, so we never touch them by hand.
- The LangGraph prompts under `prompts/` — the API exposes their outputs, not
  their inputs.

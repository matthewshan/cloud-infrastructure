# Supabase Vector DB — ADK Agent Integration

## Overview

The `supabase-vector-db` module provisions a Supabase project with pgvector enabled.
Use it as a vector store for ADK agents: long-term memory, RAG pipelines, or
semantic search over past sessions.

---

## 0. Gather Supabase variables

You need four values from Supabase before running Terraform. Collect them all first.

### `supabase_access_token`
A personal access token that lets Terraform authenticate to the Supabase API.

1. Go to **[supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens)**
2. Click **Generate new token**
3. Name it `terraform-cloud` (or similar)
4. Copy the token immediately — it is shown only once

### `organization_id`
The ID of the Supabase organization the new project will be created under.

1. Go to **[supabase.com/dashboard](https://supabase.com/dashboard)**
2. Click your organization name in the left sidebar → **Settings**
3. The org ID is in the URL: `https://supabase.com/dashboard/org/<org-id>/general`
   Copy the `<org-id>` slug (looks like `abcdefghijklmnop`)

### `database_password`
The password for the project's `postgres` user. Generate a strong one now and
save it in your password manager — you will need it again for direct DB access.

```bash
openssl rand -base64 32
```

### `region`
The Supabase region closest to you. Default is `us-east-1`.
Full list: **[supabase.com/docs/guides/platform/regions](https://supabase.com/docs/guides/platform/regions)**

Common options: `us-east-1`, `us-west-1`, `eu-west-1`, `eu-central-1`, `ap-southeast-1`

### Summary

| HCP Terraform variable  | Sensitive | Where to get it |
|-------------------------|-----------|-----------------|
| `supabase_access_token` | **Yes**   | dashboard/account/tokens (generated above) |
| `organization_id`       | No        | dashboard URL: `/org/<org-id>/general` |
| `database_password`     | **Yes**   | generate with `openssl rand -base64 32` |
| `project_name`          | No        | your choice — defaults to `adk-agents-vector` |
| `region`                | No        | your choice — defaults to `us-east-1` |

Set all five as **Terraform variables** (not environment variables) in the
`supabase-vector-db` HCP Terraform workspace before triggering a plan.

---

## 1. Apply the Terraform module

```bash
cd supabase-vector-db
terraform init
terraform apply
```

Retrieve connection outputs after apply:

```bash
terraform output project_url           # SUPABASE_URL
terraform output -raw service_role_key # SUPABASE_SERVICE_ROLE_KEY
terraform output -raw database_url     # direct Postgres connection
```

---

## 2. One-time schema setup

Connect to the database using the `database_url` output and run:

```sql
-- pgvector is pre-enabled; create a table for agent memory
CREATE TABLE agent_memory (
  id          bigserial    PRIMARY KEY,
  session_id  text         NOT NULL,
  content     text         NOT NULL,
  embedding   vector(768),           -- match your embedding model's output dimension
  created_at  timestamptz  DEFAULT now()
);

-- IVFFlat index for approximate nearest-neighbour search
-- Rule of thumb: lists ≈ sqrt(row count), recalibrate when the table grows significantly
CREATE INDEX ON agent_memory USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- RPC helper used by the Python client below
CREATE OR REPLACE FUNCTION match_agent_memory(
  query_embedding vector(768),
  match_count     int DEFAULT 5
)
RETURNS TABLE (id bigint, session_id text, content text, similarity float)
LANGUAGE sql STABLE
AS $$
  SELECT   id, session_id, content,
           1 - (embedding <=> query_embedding) AS similarity
  FROM     agent_memory
  ORDER BY embedding <=> query_embedding
  LIMIT    match_count;
$$;
```

> **Dimension note:** adjust `vector(768)` to match your model.
> Common values: `768` (text-embedding-004), `1536` (OpenAI text-embedding-3-small),
> `3072` (text-embedding-3-large).

---

## 3. Environment variables

Set these wherever the ADK agent runs (local `.env`, Cloud Run secret, etc.):

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<service_role_key>
```

Never commit these values. Store them as HCP Terraform sensitive outputs and
inject at deploy time.

---

## 4. Python wiring

Install dependencies:

```bash
pip install supabase
```

```python
import os
from supabase import create_client, Client

_client: Client | None = None

def get_client() -> Client:
    global _client
    if _client is None:
        _client = create_client(
            os.environ["SUPABASE_URL"],
            os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        )
    return _client


def store_memory(session_id: str, content: str, embedding: list[float]) -> None:
    """Persist a text chunk and its embedding for a given session."""
    get_client().table("agent_memory").insert(
        {"session_id": session_id, "content": content, "embedding": embedding}
    ).execute()


def search_memory(
    embedding: list[float], session_id: str | None = None, limit: int = 5
) -> list[dict]:
    """Return the top-k most similar memory entries."""
    result = get_client().rpc(
        "match_agent_memory",
        {"query_embedding": embedding, "match_count": limit},
    ).execute()

    rows = result.data or []
    if session_id:
        rows = [r for r in rows if r["session_id"] == session_id]
    return rows
```

---

## 5. Credential storage

| Secret                  | Where to store                                    |
|-------------------------|---------------------------------------------------|
| `supabase_access_token` | HCP Terraform workspace variable (sensitive)      |
| `database_password`     | HCP Terraform workspace variable (sensitive)      |
| `service_role_key`      | Runtime secret (Cloud Run secret / local `.env`)  |

Never put any of these in `.tfvars` files committed to git.
See `docs/security/sop-secret-hygiene.md` for the full policy.

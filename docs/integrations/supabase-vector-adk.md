# Supabase Vector DB — ADK Agent Integration

## Overview

The `supabase-vector` module provisions a Supabase project with pgvector enabled.
Use it as a vector store for ADK agents: long-term memory, RAG pipelines, or
semantic search over past sessions.

---

## 1. Apply the Terraform module

```bash
cd supabase-vector
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

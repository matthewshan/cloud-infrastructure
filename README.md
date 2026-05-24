# cloud-infrastructure

Infrastructure-as-code for Matthew Shan's cloud projects.

## Structure

```
terraform-adk-agents/   # Google Calendar service account (GCP) — see docs/plans/plan-terraform-adk-agents-migration.md
supabase-vector-db/     # Supabase project with pgvector for ADK agent memory / RAG — see docs/integrations/supabase-vector-adk.md
docs/
  integrations/         # How-to guides for wiring modules into ADK agents
  plans/                # Migration and implementation plans
  security/             # SOPs and security guidelines
```

## `supabase-vector-db` — HCP Terraform setup

### Prerequisites

1. **Supabase account** — sign up at [supabase.com](https://supabase.com) if you don't have one.

2. **Organization ID** — open the [Supabase dashboard](https://supabase.com/dashboard) and go to your
   organization's settings page. The org ID is visible in the URL:
   `https://supabase.com/dashboard/org/<org-id>/general`

3. **Personal access token** — generate one at
   [app.supabase.com/account/tokens](https://supabase.com/dashboard/account/tokens).
   Give it a descriptive name like `terraform-cloud`. Copy the token value immediately — it is not shown again.

4. **Database password** — choose a strong password for the Supabase project's `postgres` user.
   Generate one with: `openssl rand -base64 32`

### Create the HCP Terraform workspace

In the [`matthewshan` HCP Terraform organization](https://app.terraform.io/app/matthewshan/workspaces),
create a new workspace named exactly **`supabase-vector-db`**. Use the same VCS-driven workflow as the
other workspaces in this repo, pointing at this repository.

### Set workspace variables

In the workspace **Variables** tab, add the following. All five are **Terraform variables**
(not environment variables).

| Variable | Sensitive | Value |
|---|---|---|
| `organization_id` | No | Your Supabase org ID (from the dashboard URL above) |
| `project_name` | No | `adk-agents-vector` (or a custom name — becomes the Supabase project display name) |
| `region` | No | `us-east-1` (or the [region](https://supabase.com/docs/guides/platform/regions) nearest to you) |
| `supabase_access_token` | **Yes** | Personal access token generated above |
| `database_password` | **Yes** | Strong password generated above — store a copy in your password manager |

### First apply

Trigger a plan from the HCP Terraform UI (or push a commit). The apply creates one resource:

- `supabase_project.vector_db` — the Supabase project (takes ~30 s to provision)

After apply, retrieve the outputs for the next step:

```bash
cd supabase-vector-db
terraform output project_url
terraform output -raw service_role_key
terraform output -raw database_url
```

Then follow **`docs/integrations/supabase-vector-adk.md`** for the one-time SQL schema setup
(table, index, and RPC function) before connecting ADK agents.

---

## Generating GCP credentials (`GOOGLE_CREDENTIALS`)

The HCP Terraform workspace requires a `GOOGLE_CREDENTIALS` environment variable
containing the JSON key of a dedicated CI service account. Run these `gcloud`
commands once to create it:

```bash
# 1. Create the service account
gcloud iam service-accounts create terraform-ci \
  --display-name="Terraform CI" \
  --project=<your-project-id>

# 2. Grant the roles Terraform needs to manage IAM and enable APIs
gcloud projects add-iam-policy-binding <your-project-id> \
  --member="serviceAccount:terraform-ci@<your-project-id>.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding <your-project-id> \
  --member="serviceAccount:terraform-ci@<your-project-id>.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountKeyAdmin"

gcloud projects add-iam-policy-binding <your-project-id> \
  --member="serviceAccount:terraform-ci@<your-project-id>.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"

# 4. Enable APIs required by the Google Terraform provider when running as a service account
#    (these are not auto-enabled when using personal user credentials via gcloud ADC)
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  serviceusage.googleapis.com \
  --project=<your-project-id>

# 5. Download the key (do NOT commit this file)
gcloud iam service-accounts keys create terraform-ci-key.json \
  --iam-account="terraform-ci@<your-project-id>.iam.gserviceaccount.com"
```

HCP Terraform does not accept multi-line values for environment variables. Minify
the key to a single line first (PowerShell):

```powershell
# 6. Print the key as a single-line JSON string — copy this output
(Get-Content terraform-ci-key.json -Raw | ConvertFrom-Json | ConvertTo-Json -Compress -Depth 10)
```

Paste the single-line output as a sensitive **Environment variable** named
`GOOGLE_CREDENTIALS` in the HCP Terraform workspace UI.

```powershell
# 7. Delete the local key file — do NOT commit it
Remove-Item terraform-ci-key.json
```

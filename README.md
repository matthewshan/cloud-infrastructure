# cloud-infrastructure

Infrastructure-as-code for Matthew Shan's cloud projects.

## Structure

```
terraform-adk-agents/   # Google Calendar service account (GCP) — see docs/plans/plan-terraform-adk-agents-migration.md
docs/
  plans/                # Migration and implementation plans
```

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

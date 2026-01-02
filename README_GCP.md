# Google Cloud Platform Setup for "Rabbit Hole" Deployment

This guide explains how to set up the necessary Google Cloud resources and GitHub Secrets to enable the CI/CD pipeline.

## Prerequisites

- A Google Cloud Project
- `gcloud` CLI installed and authenticated
- GitHub Repository Admin access

## 1. Environment Setup

Set your environment variables for the setup commands:

```bash
export PROJECT_ID="your-project-id"
export REGION="us-central1"
export REPO_NAME="rabbit-hole-repo"
export SERVICE_ACCOUNT_NAME="github-actions-sa"
export POOL_NAME="github-actions-pool"
export PROVIDER_NAME="github-actions-provider"
export GITHUB_REPO="USER_OR_ORG/rabbit-hole" # e.g., "jules/rabbit-hole"
```

## 2. Enable APIs

Enable the required Google Cloud APIs:

```bash
gcloud services enable \
    artifactregistry.googleapis.com \
    run.googleapis.com \
    iamcredentials.googleapis.com \
    --project "${PROJECT_ID}"
```

## 3. Create Artifact Registry Repository

Create a Docker repository in Artifact Registry:

```bash
gcloud artifacts repositories create "${REPO_NAME}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="Docker repository for Rabbit Hole" \
    --project="${PROJECT_ID}"
```

## 4. Workload Identity Federation Setup

This eliminates the need for service account keys.

### Create the Workload Identity Pool:

```bash
gcloud iam workload-identity-pools create "${POOL_NAME}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --display-name="GitHub Actions Pool"
```

### Get the Pool ID:

```bash
export POOL_ID=$(gcloud iam workload-identity-pools describe "${POOL_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)")
```

### Create the OIDC Provider:

**Note:** We explicitly map the repository attribute so GitHub Actions can authenticate correctly.

```bash
gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_NAME}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --workload-identity-pool="${POOL_NAME}" \
    --display-name="GitHub Actions Provider" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository == '${GITHUB_REPO}'" \
    --issuer-uri="[https://token.actions.githubusercontent.com](https://token.actions.githubusercontent.com)"
```

## 5. Service Account Setup

Create a service account for the GitHub Action to use:

```bash
gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
    --project="${PROJECT_ID}" \
    --display-name="GitHub Actions Service Account"
```

### Grant Permissions:

Grant the service account permissions to push to Artifact Registry, deploy to Cloud Run, and manage cleanup policies.

```bash
# Allow pushing AND managing cleanup policies (Admin role required for CI cleanup)
gcloud artifacts repositories add-iam-policy-binding "${REPO_NAME}" \
    --project="${PROJECT_ID}" \
    --location="${REGION}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.admin"

# Allow deploying to Cloud Run
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/run.admin"

# Allow the GitHub SA to pass itself to the Cloud Run service
gcloud iam service-accounts add-iam-policy-binding \
    "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --project="${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
```

### Bind Service Account to Workload Identity:

Allow the GitHub repository to impersonate the service account.

```bash
gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --project="${PROJECT_ID}" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://[iam.googleapis.com/$](https://iam.googleapis.com/$){POOL_ID}/attribute.repository/${GITHUB_REPO}"
```

## 6. GitHub Secrets

Add the following secrets to your GitHub repository:

1.  `GCP_PROJECT_ID`: Your Google Cloud Project ID.
2.  `GCP_SERVICE_ACCOUNT`: The email of the service account created (e.g., `github-actions-sa@your-project-id.iam.gserviceaccount.com`).
3.  `GCP_WORKLOAD_IDENTITY_PROVIDER`: The full resource name of the provider. You can get it with:

```bash
gcloud iam workload-identity-pools providers describe "${PROVIDER_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_NAME}" \
  --format="value(name)"
```

4.  `OPENAI_API_KEY`: (Optional) If you are using OpenAI features, add your API key here.

## 7. Cost Management and Guardrails

This project uses Google Cloud services that have a free tier, but it's critical to set up guardrails to avoid unexpected charges.

### A. Set a Billing Budget & Alert

This is the most important step. It won't stop the services, but it will email you the second you hit a threshold (e.g., $1.00).

1.  Go to the **Billing** section in the GCP Console.
2.  Select **Budgets & alerts**.
3.  Create a budget for **$1.00** and set alerts at 50%, 90%, and 100%.

### B. Artifact Registry Cleanup Policy (Automated in CI)

Artifact Registry charges for storage. To keep costs low, we automatically enforce a cleanup policy during every deployment.

**1. Create the `policy.json` file**
Ensure a file named `policy.json` exists in the root of your repository with the following content:

```json
[
  {
    "name": "delete-old-images",
    "action": {"type": "Delete"},
    "condition": {
      "tagState": "any",
      "olderThan": "7d"
    }
  },
  {
    "name": "keep-last-3-images",
    "action": {"type": "Keep"},
    "condition": {
      "tagState": "any",
      "keepCount": 3
    }
  }
]
```

**2. Verify Permissions**
Ensure you ran the permission command in **Step 5** using `roles/artifactregistry.admin`. The default "Writer" role is insufficient for applying cleanup policies.

**3. Workflow Automation**
The GitHub Action is configured to run `gcloud artifacts repositories set-cleanup-policies` using this file on every deploy.

### C. Free Tier Compliance Summary

To keep "Rabbit Hole" free, ensure these settings remain in place:

| Resource | Free Tier Limit | Your Setup Status |
| :--- | :--- | :--- |
| **Cloud Run** | First 2M requests/month | **Safe** (You have `--min-instances=0`) |
| **Artifact Registry** | 0.5 GB storage/month | **Safe** (Cleanup policy runs on every deploy) |
| **Cloud Build** | 120 build-minutes/day | **Safe** (You are using GitHub Actions, not Cloud Build) |
| **Egress (Data out)** | 1 GB/month | **Safe** (Assuming low traffic for a personal demo) |

## 8. Verify

Push to the `main` branch to trigger the workflow.
#!/bin/bash
# fix_workload_identity.sh

# This script updates the Google Cloud Workload Identity Provider configuration
# to fix the "given credential is rejected by the attribute condition" error.

# Ensure the following environment variables are set before running this script:
# export PROJECT_ID="your-project-id"
# export POOL_NAME="github-actions-pool"
# export PROVIDER_NAME="github-actions-provider"
# export GITHUB_REPO="USER_OR_ORG/rabbit-hole"

if [[ -z "$PROJECT_ID" || -z "$POOL_NAME" || -z "$PROVIDER_NAME" || -z "$GITHUB_REPO" ]]; then
    echo "Error: One or more required environment variables are missing."
    echo "Please export PROJECT_ID, POOL_NAME, PROVIDER_NAME, and GITHUB_REPO."
    exit 1
fi

echo "Updating Workload Identity Provider..."

# Update the OIDC provider with the correct attribute mapping and condition
gcloud iam workload-identity-pools providers update-oidc "${PROVIDER_NAME}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --workload-identity-pool="${POOL_NAME}" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository == '${GITHUB_REPO}'"

echo "Provider updated successfully."
echo "Please retry the GitHub Actions workflow."

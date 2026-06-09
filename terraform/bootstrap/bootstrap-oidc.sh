#!/usr/bin/env bash
#
# One-time bootstrap of the GitHub Actions OIDC trust for this repo.
#
# Run this LOCALLY under an admin identity (e.g. an IAM Identity Center user
# with AdministratorAccess) rather than via GitHub Actions: Identity Center
# issues only temporary credentials, which can't live in long-lived GH secrets,
# and bootstrap is a once-per-account operation.
#
# Usage:
#   aws sso login --profile <your-sso-profile>
#   AWS_PROFILE=<your-sso-profile> ./bootstrap-oidc.sh            # scoped (default)
#   AWS_PROFILE=<your-sso-profile> PERMISSION_LEVEL=admin ./bootstrap-oidc.sh
#
# After this runs once, every other workflow authenticates to the resulting
# role via OIDC with no stored credentials.
#
set -euo pipefail

# ---- Config (override via env) ---------------------------------------------
# Role name must match the role the OIDC workflows assume (aws-terraform-plan.yml).
ROLE_NAME="${ROLE_NAME:-GitHubActions}"
# OIDC sub claim is case-sensitive: must match the real GitHub org/repo casing.
GH_REPO="${GH_REPO:-Unfitware/aws-infrastructure}"
# scoped = least-privilege customer-managed policy; admin = AdministratorAccess.
PERMISSION_LEVEL="${PERMISSION_LEVEL:-scoped}"
SCOPED_POLICY_NAME="${SCOPED_POLICY_NAME:-GitHubActions-TerraformAdmin}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SCOPED_POLICY_FILE="${REPO_ROOT}/.github/workflows/bootstrap/terraform-admin-policy.json"

# ---- Identity --------------------------------------------------------------
# Account is derived from the active credentials, not hardcoded — so the script
# bootstraps whichever account the SSO profile is pointed at.
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
CALLER="$(aws sts get-caller-identity --query Arn --output text)"
echo "Bootstrapping account ${ACCOUNT_ID} as ${CALLER}"
echo "  role=${ROLE_NAME}  repo=${GH_REPO}  permission_level=${PERMISSION_LEVEL}"

OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
ADMIN_POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"
SCOPED_POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${SCOPED_POLICY_NAME}"

# ---- OIDC provider (idempotent) --------------------------------------------
echo "Ensuring GitHub Actions OIDC provider..."
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  || echo "OIDC provider already exists, continuing."

# ---- Role + trust policy (idempotent) --------------------------------------
TRUST_POLICY="{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    {
      \"Effect\": \"Allow\",
      \"Principal\": { \"Federated\": \"${OIDC_PROVIDER_ARN}\" },
      \"Action\": \"sts:AssumeRoleWithWebIdentity\",
      \"Condition\": {
        \"StringEquals\": { \"token.actions.githubusercontent.com:aud\": \"sts.amazonaws.com\" },
        \"StringLike\":   { \"token.actions.githubusercontent.com:sub\": \"repo:${GH_REPO}:*\" }
      }
    }
  ]
}"

if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "Role ${ROLE_NAME} exists, updating trust policy..."
  aws iam update-assume-role-policy --role-name "$ROLE_NAME" \
    --policy-document "$TRUST_POLICY"
else
  echo "Creating role ${ROLE_NAME}..."
  aws iam create-role --role-name "$ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY"
fi

# ---- Permissions (authoritative: attach chosen, detach the other) ----------
if [ "$PERMISSION_LEVEL" = "admin" ]; then
  echo "Attaching AWS-managed AdministratorAccess (sandbox only)."
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$ADMIN_POLICY_ARN"
  aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$SCOPED_POLICY_ARN" \
    || echo "Scoped policy was not attached, nothing to detach."
else
  echo "Attaching least-privilege customer-managed policy: ${SCOPED_POLICY_NAME}"
  # Render the policy with the live account id (the source file uses a placeholder
  # account in its Deny-guardrail ARNs).
  RENDERED_POLICY="$(sed "s/677252573665/${ACCOUNT_ID}/g" "$SCOPED_POLICY_FILE")"
  if aws iam get-policy --policy-arn "$SCOPED_POLICY_ARN" >/dev/null 2>&1; then
    echo "Policy exists, adding a new default version..."
    aws iam create-policy-version --policy-arn "$SCOPED_POLICY_ARN" \
      --policy-document "$RENDERED_POLICY" --set-as-default
  else
    aws iam create-policy --policy-name "$SCOPED_POLICY_NAME" \
      --policy-document "$RENDERED_POLICY"
  fi
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$SCOPED_POLICY_ARN"
  aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$ADMIN_POLICY_ARN" \
    || echo "AdministratorAccess was not attached, nothing to detach."
fi

echo "Done."
echo "  Role ARN: arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
echo "  Workflows can now assume this role via OIDC — no stored credentials needed."

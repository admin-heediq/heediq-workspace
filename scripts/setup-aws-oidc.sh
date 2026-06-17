#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Heediq AWS OIDC Setup (D-043, D-044, D-045)
#
# Creates GitHub Actions OIDC identity providers and IAM roles
# in all four workload accounts. Idempotent — safe to re-run.
#
# Prerequisites:
#   - AWS CLI installed and SSO configured (run setup-claude.sh first)
#   - SSO session active: aws sso login --profile heediq-dev (etc.)
#
# Usage:
#   bash claude-workspace/scripts/setup-aws-oidc.sh
# ============================================================

# ---- config -------------------------------------------------

GITHUB_ORG="heediq"
REGION="eu-west-1"                     # D-044
OIDC_URL="token.actions.githubusercontent.com"
OIDC_THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"

# Account IDs (D-045)
SHARED_ACCOUNT="313828097088"
DEV_ACCOUNT="276594885933"
STAGING_ACCOUNT="475790160542"
PROD_ACCOUNT="438825592314"

# Local AWS CLI profiles (D-045)
SHARED_PROFILE="heediq-shared"
DEV_PROFILE="heediq-dev"
STAGING_PROFILE="heediq-staging"
PROD_PROFILE="heediq-prod"

# ---- helpers ------------------------------------------------

create_oidc_provider() {
  local profile=$1 account_id=$2
  local arn="arn:aws:iam::${account_id}:oidc-provider/${OIDC_URL}"

  if aws iam get-open-id-connect-provider \
      --open-id-connect-provider-arn "$arn" \
      --profile "$profile" &>/dev/null; then
    echo "  [skip] OIDC provider already exists"
  else
    aws iam create-open-id-connect-provider \
      --url "https://${OIDC_URL}" \
      --client-id-list sts.amazonaws.com \
      --thumbprint-list "$OIDC_THUMBPRINT" \
      --profile "$profile" >/dev/null
    echo "  [ok]   OIDC provider created"
  fi
}

create_deploy_role() {
  local profile=$1 account_id=$2 branch=$3
  local role="GitHubActionsDeployRole"

  if aws iam get-role --role-name "$role" --profile "$profile" &>/dev/null; then
    echo "  [skip] ${role} already exists"
    return
  fi

  local trust
  trust=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::${account_id}:oidc-provider/${OIDC_URL}"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "${OIDC_URL}:aud": "sts.amazonaws.com" },
      "StringLike":   { "${OIDC_URL}:sub": "repo:${GITHUB_ORG}/*:ref:refs/heads/${branch}" }
    }
  }]
}
EOF
)

  aws iam create-role \
    --role-name "$role" \
    --assume-role-policy-document "$trust" \
    --profile "$profile" >/dev/null

  aws iam attach-role-policy \
    --role-name "$role" \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \
    --profile "$profile"

  echo "  [ok]   ${role} created (branch: ${branch})"
}

create_ecr_role() {
  local profile=$1 account_id=$2
  local role="GitHubActionsECRRole"
  local policy_name="HeediqECRPushPolicy"

  if aws iam get-role --role-name "$role" --profile "$profile" &>/dev/null; then
    echo "  [skip] ${role} already exists"
    return
  fi

  local trust
  trust=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::${account_id}:oidc-provider/${OIDC_URL}"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "${OIDC_URL}:aud": "sts.amazonaws.com" },
      "StringLike": {
        "${OIDC_URL}:sub": [
          "repo:${GITHUB_ORG}/*:ref:refs/heads/develop",
          "repo:${GITHUB_ORG}/*:ref:refs/heads/main"
        ]
      }
    }
  }]
}
EOF
)

  local ecr_policy
  ecr_policy=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ecr:GetAuthorizationToken"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
        "ecr:CreateRepository",
        "ecr:DescribeRepositories"
      ],
      "Resource": "arn:aws:ecr:${REGION}:${account_id}:repository/heediq-*"
    }
  ]
}
EOF
)

  aws iam create-role \
    --role-name "$role" \
    --assume-role-policy-document "$trust" \
    --profile "$profile" >/dev/null

  aws iam put-role-policy \
    --role-name "$role" \
    --policy-name "$policy_name" \
    --policy-document "$ecr_policy" \
    --profile "$profile"

  echo "  [ok]   ${role} created (develop + main branches)"
}

# ---- main ---------------------------------------------------

echo ""
echo "=== Heediq AWS OIDC Setup ==="
echo ""

echo "1/4  shared (${SHARED_ACCOUNT})"
create_oidc_provider "$SHARED_PROFILE" "$SHARED_ACCOUNT"
create_ecr_role      "$SHARED_PROFILE" "$SHARED_ACCOUNT"

echo ""
echo "2/4  dev (${DEV_ACCOUNT})"
create_oidc_provider "$DEV_PROFILE" "$DEV_ACCOUNT"
create_deploy_role   "$DEV_PROFILE" "$DEV_ACCOUNT" "develop"

echo ""
echo "3/4  staging (${STAGING_ACCOUNT})"
create_oidc_provider "$STAGING_PROFILE" "$STAGING_ACCOUNT"
create_deploy_role   "$STAGING_PROFILE" "$STAGING_ACCOUNT" "main"

echo ""
echo "4/4  prod (${PROD_ACCOUNT})"
create_oidc_provider "$PROD_PROFILE" "$PROD_ACCOUNT"
create_deploy_role   "$PROD_PROFILE" "$PROD_ACCOUNT" "main"

echo ""
echo "=== Done. Add these to GitHub org → Settings → Variables (not Secrets): ==="
echo ""
echo "  AWS_REGION              = ${REGION}"
echo "  AWS_ECR_ROLE            = arn:aws:iam::${SHARED_ACCOUNT}:role/GitHubActionsECRRole"
echo "  AWS_DEPLOY_ROLE_DEV     = arn:aws:iam::${DEV_ACCOUNT}:role/GitHubActionsDeployRole"
echo "  AWS_DEPLOY_ROLE_STAGING = arn:aws:iam::${STAGING_ACCOUNT}:role/GitHubActionsDeployRole"
echo "  AWS_DEPLOY_ROLE_PROD    = arn:aws:iam::${PROD_ACCOUNT}:role/GitHubActionsDeployRole"
echo ""

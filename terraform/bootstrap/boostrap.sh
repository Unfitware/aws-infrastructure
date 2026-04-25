#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGION="us-west-2"
ENVIRONMENT="dev"

STATE_BUCKET="newbitsnow-${ENVIRONMENT}-tfstate-${ACCOUNT_ID}-${REGION}"
KMS_ALIAS="alias/terraform-state"

echo "Creating KMS key..."
KMS_KEY_ID=$(aws kms create-key \
  --region "$REGION" \
  --description "Terraform state KMS key for ${ENVIRONMENT}" \
  --query KeyMetadata.KeyId \
  --output text)

aws kms create-alias \
  --region "$REGION" \
  --alias-name "$KMS_ALIAS" \
  --target-key-id "$KMS_KEY_ID"

echo "Creating S3 bucket..."
aws s3api create-bucket \
  --bucket "$STATE_BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

echo "Blocking public access..."
aws s3api put-public-access-block \
  --bucket "$STATE_BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled

echo "Enabling default KMS encryption..."
aws s3api put-bucket-encryption \
  --bucket "$STATE_BUCKET" \
  --server-side-encryption-configuration "{
    \"Rules\": [
      {
        \"ApplyServerSideEncryptionByDefault\": {
          \"SSEAlgorithm\": \"aws:kms\",
          \"KMSMasterKeyID\": \"${KMS_ALIAS}\"
        },
        \"BucketKeyEnabled\": true
      }
    ]
  }"

echo "Adding lifecycle rule for old state versions..."
aws s3api put-bucket-lifecycle-configuration \
  --bucket "$STATE_BUCKET" \
  --lifecycle-configuration "{
    \"Rules\": [
      {
        \"ID\": \"expire-old-noncurrent-state-versions\",
        \"Status\": \"Enabled\",
        \"Filter\": {\"Prefix\": \"\"},
        \"NoncurrentVersionExpiration\": {
          \"NoncurrentDays\": 90
        }
      }
    ]
  }"

echo "Done."
echo "State bucket: $STATE_BUCKET"
echo "KMS key alias: $KMS_ALIAS"




# output "api_invoke_url" {
#   description = "Public MCP endpoint to add in ChatGPT"
#   value       = aws_apigatewayv2_api.http.api_endpoint
# }

# output "mcp_full_url" {
#   description = "Full POST URL for MCP"
#   value       = "${aws_apigatewayv2_api.http.api_endpoint}/mcp"
# }

# output "secret_name" {
#   description = "Secrets Manager secret name where you must set the Admin token"
#   value       = aws_secretsmanager_secret.shopify_admin.name
# }

output "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state storage"
  value       = aws_s3_bucket.state_bucket.bucket
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform state storage"
  value       = aws_s3_bucket.state_bucket.arn
}

output "state_bucket_region" {
  description = "AWS region where the S3 bucket for Terraform state storage is located"
  value       = aws_s3_bucket.state_bucket.region
}

output "state_bucket_versioning_status" {
  description = "Versioning status of the S3 bucket used for Terraform state storage"
  value       = aws_s3_bucket_versioning.state_bucket_versioning.versioning_configuration[0].status
}

output "state_bucket_encryption_algorithm" {
  description = "Server-side encryption algorithm used for the S3 bucket storing Terraform state"
  value       = aws_s3_bucket_server_side_encryption_configuration.state_bucket_encryption.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm
}

output "state_bucket_public_access_block" {
  description = "Public access block configuration for the S3 bucket used for Terraform state storage"
  value = jsonencode({
    block_public_acls       = aws_s3_bucket_public_access_block.state_bucket_public_access_block.block_public_acls
    block_public_policy     = aws_s3_bucket_public_access_block.state_bucket_public_access_block.block_public_policy
    ignore_public_acls      = aws_s3_bucket_public_access_block.state_bucket_public_access_block.ignore_public_acls
    restrict_public_buckets = aws_s3_bucket_public_access_block.state_bucket_public_access_block.restrict_public_buckets
  })
}

output "state_bucket_lifecycle_rule" {
  description = "Lifecycle rule configuration for the S3 bucket used for Terraform state storage"
  value = jsonencode({
    id     = aws_s3_bucket_lifecycle_configuration.state_bucket_lifecycle.rule[0].id
    status = aws_s3_bucket_lifecycle_configuration.state_bucket_lifecycle.rule[0].status
    noncurrent_version_expiration = {
      noncurrent_days = aws_s3_bucket_lifecycle_configuration.state_bucket_lifecycle.rule[0].noncurrent_version_expiration[0].noncurrent_days
    }
  })
}

output "state_bucket_logging_configuration" {
  description = "Logging configuration for the S3 bucket used for Terraform state storage"
  value = jsonencode({
    target_bucket = aws_s3_bucket_logging.state_bucket_logging.target_bucket
    target_prefix = aws_s3_bucket_logging.state_bucket_logging.target_prefix
  })
}

output "logs_bucket_name" {
  description = "Name of the S3 bucket used for storing access logs of the Terraform state bucket"
  value       = aws_s3_bucket.logs_bucket.bucket
}

output "logs_bucket_arn" {
  description = "ARN of the S3 bucket used for storing access logs of the Terraform state bucket"
  value       = aws_s3_bucket.logs_bucket.arn
}


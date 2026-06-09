resource "aws_s3_bucket" "state_bucket" {
  bucket = "${var.project_name}-core"
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket = "${var.project_name}-core-logs"
}

resource "aws_s3_bucket_ownership_controls" "state_bucket_ownership" {
  bucket = aws_s3_bucket.state_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "state_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.state_bucket_ownership]
  bucket     = aws_s3_bucket.state_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket_encryption" {
  bucket = aws_s3_bucket.state_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.state_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state_bucket_lifecycle" {
  bucket = aws_s3_bucket.state_bucket.id
  rule {
    id     = "expire_old_versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_logging" "state_bucket_logging" {
  bucket        = aws_s3_bucket.state_bucket.id
  target_bucket = aws_s3_bucket.logs_bucket.id
  target_prefix = "log/"
}

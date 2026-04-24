terraform {
    required_version = ">= 1.12.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.50"
        }
    }
    backend "s3" {
        bucket = "j64364-tfstate"
        key    = "dev-tfstate"
        region = "us-west-2"
        encrypt = "true"
    }
}

#
# Resources for testing and learning Terraform behaviors. 
# 

resource "aws_s3_bucket" "state_bucket" {
  bucket = "${var.project_name}-core"
}

resource "aws_s3_bucket_acl" "state_bucket_acl" {
  bucket = aws_s3_bucket.my_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket = "${var.project_name}-core"
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket_encryption" {
  bucket = "${var.project_name}-core"
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_bucket_public_access_block" {
  bucket = "${var.project_name}-core"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state_bucket_lifecycle" {
  bucket = "${var.project_name}-core"
  rule {
    id     = "expire_old_versions"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_logging" "state_bucket_logging" {
  bucket = "${var.project_name}-core"
  target_bucket = "${var.project_name}-logs"
  target_prefix = "log/"
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket = "${var.project_name}-core-logs"
}



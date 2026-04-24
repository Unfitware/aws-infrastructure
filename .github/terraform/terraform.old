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
    region = "us-west-1"
    }
}

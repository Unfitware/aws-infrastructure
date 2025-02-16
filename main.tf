terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# Configure the Provider
provider "aws" {
    region = "us-west-2"
    assume_role_with_web_identity {
        role_arn                  = "arn:aws:iam::438465144115:role/GitHubActions_PowerUser"
        session_name              = "myWebIDSessionName"
        web_identity_token_file   = "/usr/tf_user/secrets/web-identity-token"
      }
}

resource "aws_vpc" "primary_vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
}



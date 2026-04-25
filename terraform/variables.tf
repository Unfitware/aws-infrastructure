variable "project_name" {
  description = "Prefix for named resources"
  type        = string
  default     = "nbncorp"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "unfitware_domain" {
  description = "Unfitware DNS domain"
  type        = string
  default     = "unfitware.com"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "123456789123"
}
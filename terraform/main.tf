terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "env" {
  description = "Environment name (e.g. staging, prod)"
  type        = string
  default     = "staging"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "db_username" {
  description = "Aurora master username"
  type        = string
  default     = "goalert"
}

variable "db_password" {
  description = "Aurora master password"
  type        = string
  sensitive   = true
  default     = "somepassword123"
}

variable "goalert_encryption_key" {
  description = "32-byte base64 data-at-rest encryption key"
  type        = string
  sensitive   = true
  default     = "Twsf1ItKfPjUb87gg/P6UGFqAFNdMFrNt3vwfgYTUoM="
}

variable "public_url" {
  description = "GoAlert public URL (CloudFront). Set to goalert_cloudfront_url output after first apply."
  type        = string
  default     = ""
}

locals {
  common_tags = {
    Environment = var.env
    Terraform   = "true"
  }
}


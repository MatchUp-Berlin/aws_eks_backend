terraform {

  required_version = ">= 1.3.0"

  backend "s3" {
    bucket = "terraform-state-01010101"
    key    = "state/eks_state"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = ">= 2.7.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.14.0"
    }
  }
}

provider "aws" {
  region = var.AWS_REGION
}

data "aws_caller_identity" "current" {}
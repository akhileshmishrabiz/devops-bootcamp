terraform {
  required_version = "1.8.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.50"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}
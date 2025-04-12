terraform {
  required_version = "1.8.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  default_tags {
    tags = {
      day           = "20"
      account_owner = "akhileshmishrabiz@gmail.com"
      Repo          = "devops-bootcamp"
      Environment   = var.environment
    }
  }
}

# remote backend

terraform {
  backend "s3" {
    bucket  = "366140438193-terraform-state"
    key     = "devops-bootcamp/multi-lambda/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}

## google how to fix this
## hint -> migrate state if the data is there on local or import the state
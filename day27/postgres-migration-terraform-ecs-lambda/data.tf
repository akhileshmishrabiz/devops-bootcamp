data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_kms_key" "environment_kms" {
  key_id = "6a90b48a-d0d9-46e1-9686-5d4ce5495e11"
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["Default"]
  }
  # vpc id can be refrenced as -split("vpc/", data.aws_vpc.vpc.arn)[1] 
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [split("vpc/", data.aws_vpc.vpc.arn)[1]]
  }
  filter {
    name   = "tag:Name"
    values = ["RDS-Pvt-subnet-3", "RDS-Pvt-subnet-1", "RDS-Pvt-subnet-2"]
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
  # to access subnet list -> [for subnet_id, subnet in data.aws_subnet.private :  subnet.id]
}

data "aws_ecr_authorization_token" "token" {
  registry_id = aws_ecr_repository.rds_migration.registry_id
}

data "aws_kms_key" "rds_kms_key" {
  key_id = "6a90b48a-d0d9-46e1-9686-5d4ce5495e11"
}


data "aws_kms_key" "env_kms_key" {
  key_id = "6a90b48a-d0d9-46e1-9686-5d4ce5495e11"
}
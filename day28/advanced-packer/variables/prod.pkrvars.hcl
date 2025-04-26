region          = "ap-south-1"
instance_type   = "t2.medium"
ami_name_prefix = "al2023-advanced-prod"
kms_key_id      = "alias/prod-ami-encryption-key"
target_account_ids = [
  "777788889999",  # Replace with your target prod account IDs
  "000011112222"
]
vpc_id    = "vpc-abcdef1234567890"  # Specify a production VPC
subnet_id = "subnet-abcdef1234567890"  # Specify a private subnet
ssh_username = "ec2-user"
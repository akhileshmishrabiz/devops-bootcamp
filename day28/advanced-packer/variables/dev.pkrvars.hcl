region          = "ap-south-1"
instance_type   = "t2.micro"
ami_name_prefix = "al2023-advanced-dev"
kms_key_id      = "alias/ami-key"
target_account_ids = []
vpc_id    = ""  # Leave empty to use default VPC
subnet_id = ""  # Leave empty to use default subnet
ssh_username = "ec2-user"
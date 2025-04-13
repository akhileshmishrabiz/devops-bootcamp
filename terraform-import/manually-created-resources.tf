# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "https://sqs.ap-south-1.amazonaws.com/366140438193/queuewithoutencryption"
resource "aws_sqs_queue" "public_queue" {
  content_based_deduplication       = false
  deduplication_scope               = null
  delay_seconds                     = 0
  fifo_queue                        = false
  fifo_throughput_limit             = null
  kms_data_key_reuse_period_seconds = 300
  kms_master_key_id                 = null
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  name                              = "queuewithoutencryption"
  name_prefix                       = null
  policy = jsonencode({
    Id = "__default_policy_ID"
    Statement = [{
      Action = "SQS:*"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::366140438193:root"
      }
      Resource = "arn:aws:sqs:ap-south-1:366140438193:queuewithoutencryption"
      Sid      = "__owner_statement"
    }]
    Version = "2012-10-17"
  })
  receive_wait_time_seconds  = 0
  redrive_allow_policy       = null
  redrive_policy             = null
  sqs_managed_sse_enabled    = false
  tags                       = {}
  tags_all                   = {}
  visibility_timeout_seconds = 30
}

# __generated__ by Terraform from "myaccount-manually-created-bucket"
resource "aws_s3_bucket" "manual_bucket" {
  bucket              = "myaccount-manually-created-bucket"
  bucket_prefix       = null
  force_destroy       = null
  object_lock_enabled = false
  tags                = {}
  tags_all            = {}
}

# __generated__ by Terraform from "bootcamp"
resource "aws_iam_user" "bootcamp" {
  force_destroy        = null
  name                 = "bootcamp"
  path                 = "/"
  permissions_boundary = null
  tags = {
    AKIAVKP5LW2Y2HG45PZR = "day2"
    AKIAVKP5LW2Y4DUFQORC = "day1"
    AKIAVKP5LW2Y4OHWPKXL = "bootcamp day3"
    AKIAVKP5LW2Y5B5PWXTL = "day5 bootcamp call- delete soon"
    AKIAVKP5LW2YRF52XV5I = "devops zero hero repo and local"
    AKIAVKP5LW2YYRCVAXQE = "gh run and delete"
  }
  tags_all = {
    AKIAVKP5LW2Y2HG45PZR = "day2"
    AKIAVKP5LW2Y4DUFQORC = "day1"
    AKIAVKP5LW2Y4OHWPKXL = "bootcamp day3"
    AKIAVKP5LW2Y5B5PWXTL = "day5 bootcamp call- delete soon"
    AKIAVKP5LW2YRF52XV5I = "devops zero hero repo and local"
    AKIAVKP5LW2YYRCVAXQE = "gh run and delete"
  }
}

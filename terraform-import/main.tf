
# bring bucket myaccount-manually-created-bucket to terraform
# bring sqs queue queuewithoutencryption to terraform
# bring iam user bootcamp to terrafor  management 

# terraform plan -generate-config-out=manually-created-resources.tf


import {
  to = aws_s3_bucket.manual_bucket
  id = "myaccount-manually-created-bucket"
}

import {
  to = aws_sqs_queue.public_queue
  id = "https://sqs.ap-south-1.amazonaws.com/366140438193/queuewithoutencryption"
}

import {
  to = aws_iam_user.bootcamp
  id = "bootcamp"
}
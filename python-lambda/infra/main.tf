# zip the lambda code
data "archive_file" "lambda_code" {
  type        = "zip"
  source_dir  = "${path.module}/../functions/s3-scan-email"
  output_path = "s3-scan-emaila_code.zip"
}


# Create a lambda function

# var.environment
resource "aws_lambda_function" "my_lambda_function" {
  function_name = "${var.environment}-s3-scan-email"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.lambda_handler" # "file_with_lambda_code.function_that_call_lambda"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 256

  # Use the Archive data source to zip the code
  filename         = data.archive_file.lambda_code.output_path
  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  # Define environment variables
  environment {
    variables = {
      "region" = "ap-south-1"
    }
  }
}

# Create a IAM role to provide lambda permissions to do the job

resource "aws_iam_role" "lambda_role" {
    name = "${var.environment}-s3-scan-email"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}
# s3 list, s3 get object name, ses send email, cloudwatch logs

resource "aws_iam_policy" "s3_scan_email" {
    name        = "${var.environment}-s3-scan-email"
    description = "Allows read and write access to S3 buckets"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "S3:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.s3_scan_email.arn
}
# setuo a lambda trigger from cron job
# Trigger for cloud function  - cron job

# Event rule
resource "aws_cloudwatch_event_rule" "cron_lambdas" {
  name                = "cronjob"
  description         = "to triggr lambda daily 7.30 pm ist"
  schedule_expression = "cron(30 14 * * ? *)" # 7.30 pm ist
}

# Event target
resource "aws_cloudwatch_event_target" "cron_lambdas" {
  rule = aws_cloudwatch_event_rule.cron_lambdas.name
  arn  = aws_lambda_function.my_lambda_function.arn
}

# Invoke lambda permission
# Cron will trigger -> Lambda. hence Cron need permission to trigger lambda

resource "aws_lambda_permission" "cron_lambdas" {
  statement_id  = "s3-scan-email"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  function_name = aws_lambda_function.my_lambda_function.arn
  source_arn    = aws_cloudwatch_event_rule.cron_lambdas.arn
}

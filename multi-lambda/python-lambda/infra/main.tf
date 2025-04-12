# zip the lambda code
data "archive_file" "lambda_code" {
  for_each    = local.lambda_def
  type        = "zip"
  source_dir  = each.value.source_path
  output_path = "${each.value.source_path}.zip"
}

resource "aws_iam_role" "lambda_role" {
  for_each = local.lambda_def
  name     = "${var.environment}-${each.value.role_name}-${var.prefix}"

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

# # Create a lambda function

resource "aws_lambda_function" "my_lambda_function" {
  for_each      = local.lambda_def
  function_name = "${var.environment}-${each.value.function_name}-${var.prefix}"
  role          = aws_iam_role.lambda_role[each.key].arn
  handler       = "main.lambda_handler" # "file_with_lambda_code.function_that_call_lambda"
  runtime       = each.value.runtime
  timeout       = 60
  memory_size   = 256
  layers        = each.value.layers # Add the layer ARN to the function

  # Use the Archive data source to zip the code
  filename         = data.archive_file.lambda_code[each.key].output_path
  source_code_hash = data.archive_file.lambda_code[each.key].output_base64sha256

  # Define environment variables
  environment {
    variables = merge(
      {
        # Add any static environment variables here
        "environment" = "var.environment"
      },
      lookup(each.value, "environment", {}), # Merge with dynamic environment variables
    )
  }
}


resource "aws_iam_policy" "lambda_role_permissions" {
  for_each    = local.lambda_def
  name        = "${var.environment}-${each.value.function_name}-${var.prefix}"
  description = "permissions for ${each.key} lambda function"

  policy = jsonencode(each.value.permissions)
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  for_each   = local.lambda_def
  role       = aws_iam_role.lambda_role[each.key].name
  policy_arn = aws_iam_policy.lambda_role_permissions[each.key].arn
}

# # setuo a lambda trigger from cron job
# # Trigger for cloud function  - cron job



# # Event rule
# resource "aws_cloudwatch_event_rule" "cron_lambdas" {
#   name                = "cronjob"
#   description         = "to triggr lambda daily 7.30 pm ist"
#   schedule_expression = "cron(30 14 * * ? *)" # 7.30 pm ist
# }

# # Event target
# resource "aws_cloudwatch_event_target" "cron_lambdas" {
#   rule = aws_cloudwatch_event_rule.cron_lambdas.name
#   arn  = aws_lambda_function.my_lambda_function.arn
# }

# # Invoke lambda permission
# # Cron will trigger -> Lambda. hence Cron need permission to trigger lambda

# resource "aws_lambda_permission" "cron_lambdas" {
#   statement_id  = "s3-scan-email"
#   action        = "lambda:InvokeFunction"
#   principal     = "events.amazonaws.com"
#   function_name = aws_lambda_function.my_lambda_function.arn
#   source_arn    = aws_cloudwatch_event_rule.cron_lambdas.arn
# }

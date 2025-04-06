locals {

  lambda_defintion = [
    {
      function_name = "s3-scan-email"
      handler       = "lambda_function.lambda_handler"
      runtime       = "python3.12"
      source_path   = "${path.module}/../functions/s3-scan-email"
      permissions = {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : "logs:CreateLogGroup",
            "Resource" : "*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource" : [
              "*"
            ]
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "S3:*"
            ],
            "Resource" : [
              "*"
            ]
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "ses:SendEmail",
              "ses:SendRawEmail"
            ],
            "Resource" : [
              "*"
            ]
          }
        ]
      }
      role_name = "s3-scan-email"

    },

    {
      function_name = "iam-key-rotation"
      handler       = "lambda_function.lambda_handler"
      runtime       = "python3.12"
      source_path   = "${path.module}/../functions/iam-key-rotation"
      permissions = {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : "logs:CreateLogGroup",
            "Resource" : "*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource" : [
              "*"
            ]
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "iam:*"
            ],
            "Resource" : [
              "*"
            ]
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "ses:SendEmail",
              "ses:SendRawEmail"
            ],
            "Resource" : [
              "*"
            ]
          }
        ]
      }
      role_name     = "iam-key-rotation"
      environment = {
        cloud_team_email = var.cloud_team_email
      }
    }

  ]

  lambda_def = { for i in local.lambda_defintion : i.function_name => i }


}


# lambda_defintion = {
#       + iam-key-rotation = {
#           + environment   = {
#               + cloud_team_email = "akhileshmishra121990@gmail.com"
#             }
#           + function_name = "iam-key-rotation"
#           + handler       = "lambda_function.lambda_handler"
#           + permissions   = {}
#           + role_name     = "iam-key-rotation"
#           + runtime       = "python3.12"
#           + source_path   = "./../functions/iam-key-rotation"
#         }
#       + s3-scan-email    = {
#           + function_name = "s3-scan-email"
#           + handler       = "lambda_function.lambda_handler"
#           + permissions   = {}
#           + role_name     = "s3-scan-email"
#           + runtime       = "python3.12"
#           + source_path   = "./../functions/s3-scan-email"
#         }
#     }
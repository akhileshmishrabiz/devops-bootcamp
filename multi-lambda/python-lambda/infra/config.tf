locals {

  lambda_defintion = [
    # {
    #   function_name = "s3-scan-email"
    #   handler       = "lambda_function.lambda_handler"
    #   runtime       = "python3.12"
    #   source_path   = "${path.module}/../functions/s3-scan-email"
    #   permissions = {
    #     "Version" : "2012-10-17",
    #     "Statement" : [
    #       {
    #         "Effect" : "Allow",
    #         "Action" : "logs:CreateLogGroup",
    #         "Resource" : "*"
    #       },
    #       {
    #         "Effect" : "Allow",
    #         "Action" : [
    #           "logs:CreateLogStream",
    #           "logs:PutLogEvents"
    #         ],
    #         "Resource" : [
    #           "*"
    #         ]
    #       },
    #       {
    #         "Effect" : "Allow",
    #         "Action" : [
    #           "S3:*"
    #         ],
    #         "Resource" : [
    #           "*"
    #         ]
    #       },
    #       {
    #         "Effect" : "Allow",
    #         "Action" : [
    #           "ses:SendEmail",
    #           "ses:SendRawEmail"
    #         ],
    #         "Resource" : [
    #           "*"
    #         ]
    #       }
    #     ]
    #   }
    #   role_name = "s3-scan-email"

    # },

    # {
    #   function_name = "iam-key-rotation"
    #   handler       = "lambda_function.lambda_handler"
    #   runtime       = "python3.12"
    #   source_path   = "${path.module}/../functions/iam-key-rotation"
    #   permissions = {
    #     "Version" : "2012-10-17",
    #     "Statement" : [
    #       {
    #         "Effect" : "Allow",
    #         "Action" : "logs:CreateLogGroup",
    #         "Resource" : "*"
    #       },
    #       {
    #         "Effect" : "Allow",
    #         "Action" : [
    #           "logs:CreateLogStream",
    #           "logs:PutLogEvents"
    #         ],
    #         "Resource" : [
    #           "*"
    #         ]
    #       },
    #       {
    #         "Effect" : "Allow",
    #         "Action" : [
    #           "iam:*"
    #         ],
    #         "Resource" : [
    #           "*"
    #         ]
    #       },
    #       {
    #         "Effect" : "Allow",
    #         "Action" : [
    #           "ses:SendEmail",
    #           "ses:SendRawEmail"
    #         ],
    #         "Resource" : [
    #           "*"
    #         ]
    #       }
    #     ]
    #   }
    #   role_name     = "iam-key-rotation"
    #   environment = {
    #     cloud_team_email = var.cloud_team_email
    #   }
    # },
    {
      function_name = "get-cve-data"
      handler       = "main.lambda_handler"
      runtime       = "python3.12"
      layers = [
        module.layers["requests"].lambda_layer_arn,
      ]
      source_path = "${path.module}/../functions/cve-detail-fetch"
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


        ]
      }
      role_name = "get-cve-data"

    },

  ]

  lambda_def = { for i in local.lambda_defintion : i.function_name => i }

  layer_definitions = [
    {
      "identifier" : "requests",
      "description" : "Contains some python packages",
      "path" : "layers/requests",
      "compatible_runtimes" : ["python3.11", "python3.12"]
    },
    {
      "identifier" : "pandas",
      "description" : "Contains some python packages",
      "path" : "layers/pandas",
      "compatible_runtimes" : ["python3.11", "python3.12"]
    },
    {
      "identifier" : "openpyxl",
      "description" : "Contains some python packages",
      "path" : "layers/openpyxl",
      "runtime" : "python3.12",
      "compatible_runtimes" : ["python3.11", "python3.12"]
    },

  ]
  layers_info = { for i in local.layer_definitions : i.identifier => i }

}

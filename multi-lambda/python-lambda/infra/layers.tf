module "layers" {
  for_each = local.layers_info
  source   = "terraform-aws-modules/lambda/aws"
  version  = "7.7.0"

  create_layer = true
  layer_name   = "${var.environment}-${each.key}"
  description  = each.value.description
  source_path = [
    {
      path             = "${path.module}/${each.value.path}",
      pip_requirements = true,
      prefix_in_zip    = "python"
    },

  ]

  runtime                  = lookup(each.value, "runtime", var.lambda_default_settings["runtime"])
  store_on_s3              = true
  s3_prefix                = "layers/${each.key}"
  s3_bucket                = aws_s3_bucket.lambda_artifacts.id  
  compatible_architectures = ["x86_64"]
}


data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "lambda_artifacts" {
  bucket = "${data.aws_caller_identity.current.account_id}-lambda-artifacts"
  tags = {
    Name = "lambda-artifacts"
  }
}
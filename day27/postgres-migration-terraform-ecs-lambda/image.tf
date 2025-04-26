locals {
  repository = aws_ecr_repository.rds_migration.repository_url
  tag        = "latest"
}

resource "null_resource" "ecr_image" {
  count = var.ecr_existing_repository_uri == "" ? 1 : 0
  depends_on = [
    aws_ecr_repository.rds_migration
  ]

  provisioner "local-exec" {
    environment = {
      AWS_DEFAULT_REGION = data.aws_region.current.name
    }
    command = <<Settings
            cd ${path.module}/image/
            ../awsdocker.sh '${aws_ecr_repository.rds_migration.repository_url}' '${data.aws_ecr_authorization_token.token.password}' local.tag
            Settings
  }
}

locals {

  flask_ecs_services_vars = {
    aws_ecr_repository            = aws_ecr_repository.flask_app.repository_url
    tag                           = var.tag
    container_name                = var.app_name
    aws_cloudwatch_log_group_name = "/aws/ecs/${var.environment}-${var.app_name}"
    db_link                       = "postgresql://${aws_db_instance.postgres.username}:${random_password.dbs_random_string.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
    environment                   = var.environment
    db_link_secret                = aws_secretsmanager_secret.db_link.id
    db_host                       = aws_db_instance.postgres.address
  }
}
variable "region" {
  description = "The region in which the resources will be created"
  default     = "ap-south-1"
}

variable "zone1" {
  description = "The availability zone 1"
  default     = "ap-south-1a"
}

variable "zone2" {
  description = "The availability zone 2"
  default     = "ap-south-1b"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "The environment in which the resources will be created"
  default     = "dev"
}
variable "prefix" {
  description = "The prefix for the resources"
}
variable "app_name" {
  description = "The name of the application"
  default     = "2-tier-flask"
}

variable "db_default_settings" {
  type = any
  default = {
    allocated_storage       = 30
    max_allocated_storage   = 50
    engine_version          = 14.15
    instance_class          = "db.t3.micro"
    backup_retention_period = 2
    db_name                 = "postgres"
    ca_cert_name            = "rds-ca-rsa2048-g1"
    db_admin_username       = "postgres"
  }
}

variable "flask_app_template_file" {
  description = "The path to the template file for the flask app"
}

variable "flask_app_cpu" {
  description = "CPU units for the flask-app service"
  type        = number
  default     = 1024
}

variable "flask_app_memory" {
  description = "Memory in MiB for the flask-app service"
  type        = number
  default     = 2048
}

variable "tag" {
}

variable "desired_flask_task_count" {
  description = "The desired number of tasks for the flask-app service"
  type        = number
  default     = 2
}

variable "public_hosted_zone_id" {
  description = "The hosted zone id for the public domain"
  default     = "livingdevops.com"
}

variable "domain_name" {
  description = "The domain name for the application"
}
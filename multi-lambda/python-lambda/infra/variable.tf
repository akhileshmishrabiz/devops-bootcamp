variable "environment" {
  default = "dev"
}

variable "cloud_team_email" {
  default = "akhileshmishra121990@gmail.com"
}
variable "prefix" {
  default = "day21"
}

variable "lambda_default_settings" {
  type = object({
    timeout             = number
    runtime             = string
    compatible_runtimes = list(string)
  })
  default = {
    timeout             = 50
    runtime             = "python3.12"
    compatible_runtimes = ["python3.11", "python3.12"]
  }
}
variable "application_port_number" {
  type    = number
  default = 3003
}

variable "aws_ecr_repository_name" {
  type    = string
  default = "simple-node-app-with-terraform-on-aws"
}

variable "fargate_desired_count" {
  type    = number
  default = 1
}
output "port" {
  value = var.application_port_number
}

output "ecr_repo_url" {
  value = aws_ecr_repository.ecr.repository_url
}


resource "aws_ecr_repository" "ecr" {
  provider     = aws.default
  name         = var.aws_ecr_repository_name
  force_delete = true
}

output "ecr_repo_url" {
  value = aws_ecr_repository.ecr.repository_url
}
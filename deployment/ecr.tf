resource "aws_ecr_repository" "ecr" {
  provider     = aws.default
  name         = "simple-node-app-with-terraform-on-aws"
  force_delete = true
}

output "ecr_repo_url" {
  value = aws_ecr_repository.ecr.repository_url
}
resource "aws_ecr_repository" "ecr" {
  provider     = aws.default
  name         = var.aws_ecr_repository_name
  force_delete = true
}

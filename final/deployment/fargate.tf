resource "aws_ecs_task_definition" "backend_task" {
  family = "backend_example_app_family"

  // Fargate is a type of ECS that requires awsvpc network_mode
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  // Valid sizes are shown here: https://aws.amazon.com/fargate/pricing/
  memory = "512"
  cpu    = "256"

  // Fargate requires task definitions to have an execution role ARN to support ECR images
  execution_role_arn = aws_iam_role.ecs_role.arn

  container_definitions = jsonencode([
    {
      name      = "example_app_container"
      image     = "${aws_ecr_repository.ecr.repository_url}:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = var.application_port_number
          hostPort      = var.application_port_number
        }
      ]
    }
  ])
}

resource "aws_ecs_cluster" "backend_cluster" {
  name = "backend_cluster_example_app"
}

resource "aws_ecs_service" "backend_service" {
  name = "backend_service"

  cluster         = aws_ecs_cluster.backend_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn

  launch_type   = "FARGATE"
  desired_count = var.fargate_desired_count

  network_configuration {
    subnets          = ["${aws_subnet.public_a.id}", "${aws_subnet.public_b.id}"]
    security_groups  = ["${aws_security_group.custom_security_group.id}"]
    assign_public_ip = true
  }
}
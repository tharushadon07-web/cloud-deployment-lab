data "aws_caller_identity" "current" {}
data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" {
  filter { name = "vpc-id" values = [data.aws_vpc.default.id] }
}
resource "aws_ecr_repository" "app" {
  name                 = var.project
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  force_delete = true
}
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project}"
  retention_in_days = 7
}
resource "aws_iam_role" "execution" {
  name = "${var.project}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole"}]
  })
}
resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_ecs_cluster" "app" { name = "cloud-lab" }
resource "aws_security_group" "web" {
  name_prefix = "cloud-lab-web-"
  vpc_id = data.aws_vpc.default.id
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Demo public HTTP endpoint (no sensitive data)"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_ecs_task_definition" "app" {
  count = var.enable_service ? 1 : 0
  family = "cloud-lab"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.execution.arn
  container_definitions = jsonencode([{ 
    name = "web", essential = true,
    image = "${aws_ecr_repository.app.repository_url}:latest",
    portMappings = [{containerPort = 8080, protocol = "tcp"}],
    environment = [{name = "APP_ENV", value = "aws-ecs"}],
    logConfiguration = {
      logDriver = "awslogs",
      options = {"awslogs-group" = aws_cloudwatch_log_group.app.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "web"}
    }
  }])
}
resource "aws_ecs_service" "app" {
  count = var.enable_service ? 1 : 0
  name = "cloud-lab-service"
  cluster = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app[0].arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.web.id]
    assign_public_ip = true
  }
  depends_on = [aws_iam_role_policy_attachment.execution]
}

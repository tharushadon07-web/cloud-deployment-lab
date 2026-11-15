output "ecr_url" { value = aws_ecr_repository.app.repository_url }
output "cluster_name" { value = aws_ecs_cluster.app.name }
output "service_name" { value = var.enable_service ? aws_ecs_service.app[0].name : "not-enabled" }

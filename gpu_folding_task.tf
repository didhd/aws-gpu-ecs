/*
resource "aws_ecs_task_definition" "folding_gpu_task" {
  family                   = "folding-gpu-task"
  requires_compatibilities = ["EC2"]
  network_mode            = "awsvpc"
  cpu                     = "2048"
  memory                  = "4096"

  execution_role_arn = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_tasks_role.arn

  container_definitions = jsonencode([
    {
      name      = "folding-gpu"
      image     = "foldingathome/fah-gpu:latest"
      cpu       = 2048
      memory    = 4096
      essential = true

      environment = [
        {
          name  = "TEAM"
          value = "0"  # Equipo por defecto
        },
        {
          name  = "POWER"
          value = "full"
        },
        {
          name  = "PUID"
          value = "1000"
        },
        {
          name  = "PGID"
          value = "1000"
        },
        {
          name  = "FAH_USER"
          value = "Anonymous"
        },
        {
          name  = "FAH_PASSKEY"
          value = var.folding_passkey
        }
      ]

      resourceRequirements = [
        {
          type  = "GPU"
          value = "1"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/folding-gpu-task"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "folding"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "folding_logs" {
  name              = "/ecs/folding-gpu-task"
  retention_in_days = 30
}

resource "aws_ecs_service" "folding_service" {
  name            = "folding-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.folding_gpu_task.arn
  desired_count   = 1

  network_configuration {
    subnets          = aws_subnet.private_subnet[*].id
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_asg_capacity_provider.name
    weight           = 1
    base            = 1
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.instance-type == g4dn.xlarge"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
*/
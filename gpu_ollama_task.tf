resource "aws_ecs_task_definition" "ollama_gpu_task" {
  family                   = "ollama-gpu-task"
  requires_compatibilities = ["EC2"]
  network_mode            = "awsvpc"
  cpu                     = "2048"
  memory                  = "8192"  # Ollama require a lot of memory for the models

  execution_role_arn = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_tasks_role.arn

  container_definitions = jsonencode([
    {
      name      = "ollama-gpu"
      image     = "ollama/ollama:latest"
      cpu       = 2048
      memory    = 8192
      essential = true

      resourceRequirements = [
        {
          type  = "GPU"
          value = "1"
        }
      ]

      portMappings = [
        {
          containerPort = 11434
          hostPort      = 11434
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/ollama-gpu-task"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ollama"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ollama_logs" {
  name              = "/ecs/ollama-gpu-task"
  retention_in_days = 30
}

# Ollama specific Security Group
resource "aws_security_group" "ollama_sg" {
  name        = "ollama-sg"
  description = "Security group for Ollama API"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Only visible from VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ollama-sg"
  }
}

resource "aws_ecs_service" "ollama_service" {
  name            = "ollama-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.ollama_gpu_task.arn
  desired_count   = 1

  network_configuration {
    subnets          = aws_subnet.private_subnet[*].id
    security_groups  = [aws_security_group.ollama_sg.id, aws_security_group.ecs_tasks_sg.id]
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

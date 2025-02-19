resource "aws_ecs_task_definition" "ollama_gpu_task" {
  family                   = "ollama-gpu-task"
  requires_compatibilities = ["EC2"]
  network_mode            = "awsvpc"
  cpu                     = "2048"
  memory                  = "8192"  # Ollama necesita bastante memoria para los modelos

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

      # Comando para iniciar Ollama y cargar un modelo específico
      command = [
        "sh", 
        "-c", 
        "ollama serve & sleep 10 && ollama pull llama2 && tail -f /dev/null"
      ]
    }
  ])
}

resource "aws_cloudwatch_log_group" "ollama_logs" {
  name              = "/ecs/ollama-gpu-task"
  retention_in_days = 30
}

# Security group específico para Ollama
resource "aws_security_group" "ollama_sg" {
  name        = "ollama-sg"
  description = "Security group for Ollama API"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Solo accesible desde la VPC
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

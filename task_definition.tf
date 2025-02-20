resource "aws_ecs_task_definition" "gpu_task" {
  family                   = "ecs-gpu-task-def"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  #   cpu                      = "100" # Adjust based on your container's requirements
  #   memory                   = "80"  # Adjust based on your container's requirements

  execution_role_arn = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_tasks_role.arn

  container_definitions = jsonencode([
    {
      name      = "my-gpu-container"
      image     = "nvidia/cuda:11.0.3-base" # Specify your Docker image here
      cpu       = 100
      memory    = 80
      essential = true
      command   = ["sh", "-c", "nvidia-smi"],
      environment = [
        {
          name  = "ENV_VAR_NAME"
          value = "value"
        },
      ]
      resourceRequirements = [
        {
          type  = "GPU"
          value = "1" # Specify the number of GPUs required
        },
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/ecs-gpu-task-def",
          awslogs-region        = var.aws_region,
          awslogs-stream-prefix = "ecs",
        },
      },
    },
  ])
}

resource "aws_iam_role" "ecs_tasks_execution_role" {
  name = "ecs-tasks-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_role" "ecs_tasks_role" {
  name = "ecs-tasks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com",
        },
      },
    ],
  })
}

# Attach the necessary policy to the execution role to allow ECS tasks to pull images and store logs
resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role_policy" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_cloudwatch_logs" {
  name = "ecs-cloudwatch-logs"
  role = aws_iam_role.ecs_tasks_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs_logs.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/ecs-gpu-task-def"

  retention_in_days = 30 # Optional: Adjust the retention period as needed
}

output "run_ecs_task_command" {
  value       = <<EOH
aws ecs run-task \
    --cluster ${aws_ecs_cluster.my_cluster.name} \
    --task-definition ecs-gpu-task-def \
    --placement-constraints "type=memberOf,expression=attribute:ecs.instance-type == g4dn.xlarge" \
    --network-configuration "awsvpcConfiguration={subnets=[${join(",", formatlist("\"%s\"", aws_subnet.public_subnet[*].id))}],securityGroups=[\"${aws_security_group.ecs_tasks_sg.id}\"]}" \
    --region ${var.aws_region}
EOH
  description = "Run this AWS CLI command to start the ECS task with the specified configuration."
}

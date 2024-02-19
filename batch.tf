resource "aws_batch_compute_environment" "example" {
  compute_environment_name = "example"
  type                     = "MANAGED"

  compute_resources {
    instance_type = ["g4dn.xlarge"]
    max_vcpus     = 16
    min_vcpus     = 0
    desired_vcpus = 4

    type = "EC2"

    subnets = aws_subnet.public_subnet[*].id
    security_group_ids = [
      aws_security_group.ecs_tasks_sg.id,
    ]

    instance_role = aws_iam_instance_profile.ecs_instance_profile.arn
  }

  service_role = aws_iam_role.aws_batch_service_role.arn
}

resource "aws_iam_role" "aws_batch_service_role" {
  name = "awsBatchServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "batch.amazonaws.com",
        },
      },
    ],
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"]
}


resource "aws_batch_job_queue" "example" {
  name                 = "g4dn-queue"
  state                = "ENABLED"
  priority             = 1
  compute_environments = [aws_batch_compute_environment.example.arn]
}

resource "aws_batch_job_definition" "example" {
  name = "example"
  type = "container"

  container_properties = jsonencode({
    command = ["sh", "-c", "nvidia-smi"],
    image   = "nvidia/cuda:11.0.3-base",
    memory  = 8192,
    vcpus   = 4,
    resourceRequirements = [
      {
        type  = "GPU",
        value = "1"
      },
    ],
    executionRoleArn = aws_iam_role.ecs_tasks_execution_role.arn
  })
}

output "submit_job_command" {
  value       = <<EOT
aws batch submit-job \
    --job-name example-job \
    --job-queue ${aws_batch_job_queue.example.name} \
    --job-definition ${aws_batch_job_definition.example.name} \
    --region us-east-2
EOT
  description = "Use this command to submit a job to AWS Batch."
}

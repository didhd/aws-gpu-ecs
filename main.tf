provider "aws" {
  region = "us-east-2"
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-ecs-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.my_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_asg_capacity_provider.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_asg_capacity_provider.name
    weight            = 1
    base              = 1
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "my-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_instance_role.name
}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-gpu-hvm-*-x86_64-ebs"]
  }
}

resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "ecs-launch-template-"
  image_id      = data.aws_ami.ecs_ami.id # Update this with the latest ECS-optimized AMI ID for your region
  instance_type = "g4dn.xlarge"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.my_cluster.name} >> /etc/ecs/ecs.config
echo ECS_ENABLE_GPU_SUPPORT=true >> /etc/ecs/ecs.config
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ECS Instance - g4dn.xlarge"
    }
  }
}

resource "aws_autoscaling_group" "ecs_asg" {
  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  min_size            = 0
  max_size            = 10
  desired_capacity    = 2
  vpc_zone_identifier = [for id in aws_subnet.private_subnet.*.id : id]

  tag {
    key                 = "Name"
    value               = "ECS Instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "ecsCluster"
    value               = aws_ecs_cluster.my_cluster.name
    propagate_at_launch = true
  }
}


resource "aws_ecs_capacity_provider" "ecs_asg_capacity_provider" {
  name = "my-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "DISABLED" # 필요에 따라 "ENABLED" 또는 "DISABLED"

    managed_scaling {
      status                    = "ENABLED" # 필요에 따라 "ENABLED" 또는 "DISABLED"
      target_capacity           = 100       # 원하는 타겟 용량 비율
      minimum_scaling_step_size = 1         # 최소 스케일링 단계 크기
      maximum_scaling_step_size = 100       # 최대 스케일링 단계 크기
    }
  }
}

# Bonus: Launch Template + ASG + scale-out policy.
# Prerequisites: ALB, two Target Groups, EC2 security group, and ECR repos already exist (from steps 01–04).

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Ubuntu 24.04 AMI (linux/amd64 for EC2) ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

# --- IAM role for EC2: ECR read (so instances can pull images) ---
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ec2_ecr" {
  name = "devops-ec2-ecr-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_ecr.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_ecr" {
  name = "devops-ec2-ecr-profile"
  role = aws_iam_role.ec2_ecr.name
}

# --- User-data: docker-compose content as base64 ---
locals {
  docker_compose_content = templatefile("${path.module}/docker-compose.yml.tpl", {
    ecr_uri = var.ecr_uri
  })
  docker_compose_b64 = base64encode(local.docker_compose_content)
  user_data_rendered = templatefile("${path.module}/user-data.sh.tpl", {
    aws_region        = var.aws_region
    ecr_uri          = var.ecr_uri
    docker_compose_b64 = local.docker_compose_b64
  })
}

# --- Launch Template: Ubuntu 24.04, Docker + compose in user-data ---
resource "aws_launch_template" "devops" {
  name_prefix   = "devops-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_ecr.arn
  }

  vpc_security_group_ids = [var.ec2_security_group_id]

  user_data = base64encode(local.user_data_rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "devops-asg-instance"
    }
  }

  tags = {
    Name = "devops-launch-template"
  }
}

# --- Auto Scaling Group: min=2, desired=2, max=4 ---
resource "aws_autoscaling_group" "devops" {
  name                = "devops-asg"
  vpc_zone_identifier  = var.subnet_ids
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  health_check_type   = "ELB"
  health_check_grace_period = 300

  target_group_arns = var.target_group_arns

  launch_template {
    id      = aws_launch_template.devops.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "devops-asg-instance"
    propagate_at_launch  = true
  }
}

# --- Scale-out: CPU > 40% (target tracking; scale when average exceeds target) ---
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "devops-scale-out"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.devops.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value        = var.scale_out_cpu_percent
    scale_in_cooldown   = 300
    scale_out_cooldown  = 60
  }
}

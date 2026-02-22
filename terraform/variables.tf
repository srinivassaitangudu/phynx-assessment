# Bonus: Terraform variables for ASG + Launch Template.
# Fill in terraform.tfvars (copy from terraform.tfvars.example).

variable "aws_region" {
  description = "AWS region (e.g. us-east-1). Must match where ALB and ECR exist."
  type        = string
}

variable "ecr_uri" {
  description = "ECR registry host, e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com (no https://)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB and target groups live."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs (at least 2, in different AZs) for the ASG."
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "Security group ID for EC2 instances (devops-ec2-sg). Must allow 5000/5001 from ALB."
  type        = string
}

variable "target_group_arns" {
  description = "List of ALB target group ARNs [service1_tg_arn, service2_tg_arn] to attach to the ASG."
  type        = list(string)
}

variable "key_name" {
  description = "EC2 key pair name for SSH access."
  type        = string
}

variable "asg_min_size" {
  description = "ASG minimum size."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "ASG maximum size."
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "ASG desired capacity."
  type        = number
  default     = 2
}

variable "scale_out_cpu_percent" {
  description = "Scale out when CPU exceeds this percent."
  type        = number
  default     = 40
}

variable "scale_out_evaluation_periods" {
  description = "Number of periods (5 min each) CPU must be above threshold to scale out."
  type        = number
  default     = 1
}

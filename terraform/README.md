# Bonus: Terraform – Launch Template + ASG + Scale-out

This folder provisions the **bonus** items: a Launch Template (Docker + ECR + docker-compose in user-data), an Auto Scaling Group (min=2, desired=2, max=4) attached to your existing ALB Target Groups, and a scale-out policy (CPU > 40%).

## Prerequisites

- You have already completed **steps 01–04**: ECR images pushed, ALB and two Target Groups created, EC2 security group created.
- **Do not** run this before the ALB and target groups exist; the ASG attaches to them.
- Optionally **terminate** the two manually launched EC2 instances before applying, so only ASG instances serve traffic (or leave them and have 4 instances total).

## Setup

1. Copy the example vars and fill in your IDs:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your: aws_region, ecr_uri, vpc_id, subnet_ids,
   # ec2_security_group_id, target_group_arns, key_name
   ```

2. Initialize and apply:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. After apply, new instances will launch, run user-data (install Docker, pull from ECR, start compose), and register with the ALB. Wait for targets to become healthy, then test:

   ```bash
   curl -s http://<ALB-DNS>/service1
   curl -s http://<ALB-DNS>/service2
   ```

## Scale-out evidence

- **ASG:** EC2 → Auto Scaling Groups → `devops-asg` → Activity history.
- **CPU:** CloudWatch → Metrics → EC2 → By Auto Scaling Group → `devops-asg` → CPUUtilization. To trigger scale-out, generate load (e.g. loop `curl` to the ALB or run a CPU stress tool on an instance).

## Destroy (bonus resources only)

```bash
terraform destroy
```

This removes the ASG, Launch Template, and IAM role/profile. It does **not** remove the ALB, target groups, or ECR; use the cleanup script for full teardown.

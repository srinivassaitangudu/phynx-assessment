# Step F: Bonus (IaC) and Cleanup

**Optional:** Terraform/ASG. **Required for deliverables:** Note that AWS resources have been torn down after the assessment.

---

## Part 1: Bonus – Infrastructure as Code (implemented)

The repo includes **Terraform** in **`terraform/`** that provisions:

1. **Launch Template** – Ubuntu 24.04, t2.micro, user-data: install Docker + AWS CLI, write docker-compose (with your ECR URIs), ECR login via instance profile, `docker compose pull` and `up -d`.
2. **Auto Scaling Group** – min=2, desired=2, max=4, attached to your **existing** ALB Target Groups.
3. **Scale-out policy** – Target tracking on CPU (target 40%); scale out when average CPU exceeds 40%.

### How to run the bonus

1. Complete steps **01–04** (ECR, ALB, Target Groups, EC2 security group). Optionally terminate the two manual EC2 instances so only ASG instances serve traffic.
2. **Copy and fill variables:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars: aws_region, ecr_uri, vpc_id, subnet_ids,
   # ec2_security_group_id, target_group_arns, key_name
   ```
3. **Apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
4. Wait for new instances to be healthy in the ALB, then test `curl http://<ALB-DNS>/service1` and `/service2`.
5. **Evidence:** EC2 → Auto Scaling Groups → `devops-asg` → Activity; CloudWatch → Metrics → CPUUtilization by ASG. Trigger scale-out with load (e.g. loop `curl` or CPU stress).

See **`terraform/README.md`** for details.

---

## Part 2: Cleanup (required for submission)

After testing and screenshots, **tear down all resources** so you don’t incur ongoing cost.

### Option A – Use the cleanup script (recommended)

1. **If you used the Terraform bonus**, destroy it first:
   ```bash
   cd terraform && terraform destroy
   ```
2. **Set variables** (from your steps 02–04), then run:
   ```bash
   export AWS_REGION=us-east-1
   export INSTANCE_1=i-xxx INSTANCE_2=i-xxx   # from step 02 (omit if only ASG was used)
   export ALB_ARN=arn:aws:elasticloadbalancing:...
   export TG1_ARN=arn:aws:elasticloadbalancing:...
   export TG2_ARN=arn:aws:elasticloadbalancing:...
   export SG_ID=sg-xxx
   export ALB_SG=sg-xxx
   ./scripts/cleanup.sh
   ```

The script will prompt for confirmation, then delete ALB, target groups, EC2 instances (if set), security groups, and ECR repos in the correct order.

### Option B – Manual commands

See “Resources to remove” below; delete in this order:

1. **Terraform (if used):** `cd terraform && terraform destroy`
2. **EC2 instances** – Terminate manual instances (or ASG is gone after Terraform destroy).
3. **ALB** – Delete the load balancer (listeners go with it).
4. **Target Groups** – Delete both.
5. **Security groups** – Delete `devops-alb-sg`, then `devops-ec2-sg`.
6. **ECR** – Force-delete both repositories.

Example (replace IDs):

```bash
aws ec2 terminate-instances --instance-ids $INSTANCE_1 $INSTANCE_2 --region $AWS_REGION
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN --region $AWS_REGION
aws elbv2 delete-target-group --target-group-arn $TG1_ARN --region $AWS_REGION
aws elbv2 delete-target-group --target-group-arn $TG2_ARN --region $AWS_REGION
aws ec2 delete-security-group --group-id $ALB_SG --region $AWS_REGION
aws ec2 delete-security-group --group-id $SG_ID --region $AWS_REGION
aws ecr delete-repository --repository-name service1 --force --region $AWS_REGION
aws ecr delete-repository --repository-name service2 --force --region $AWS_REGION
```

### Deliverable – Cleanup confirmation

Fill in **`CLEANUP_CONFIRMATION.md`** (in the repo root) with the date and region, and list what was deleted. Add a short note to your submission, e.g.:

- “All AWS resources created for this assessment have been torn down as of [date].”

This satisfies the “Cleanup confirmation” requirement in the problem statement.

#!/usr/bin/env bash
# Teardown all AWS resources created for the devops assessment.
# Set the variables below (or export them) before running. Run from repo root or scripts/.
#
# Usage:
#   export AWS_REGION=us-east-1
#   export INSTANCE_1=i-xxx INSTANCE_2=i-xxx  # from step 02 (skip if using ASG only)
#   export ALB_ARN=arn:aws:elasticloadbalancing:...
#   export TG1_ARN=arn:aws:elasticloadbalancing:...
#   export TG2_ARN=arn:aws:elasticloadbalancing:...
#   export SG_ID=sg-xxx          # devops-ec2-sg
#   export ALB_SG=sg-xxx         # devops-alb-sg
#   ./scripts/cleanup.sh
#
# If you used the Terraform bonus, run first: cd terraform && terraform destroy
# Then run this script to remove ALB, TGs, security groups, ECR.

set -e

AWS_REGION="${AWS_REGION:-us-east-1}"

echo "Region: $AWS_REGION"
echo "This will delete: ALB, Target Groups, EC2 instances (if set), Security Groups, ECR repos."
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[yY]$ ]]; then
  echo "Aborted."
  exit 0
fi

# --- 1. Terminate manual EC2 instances (from step 02) ---
if [ -n "$INSTANCE_1" ] || [ -n "$INSTANCE_2" ]; then
  INSTANCES=""
  [ -n "$INSTANCE_1" ] && INSTANCES="$INSTANCES $INSTANCE_1"
  [ -n "$INSTANCE_2" ] && INSTANCES="$INSTANCES $INSTANCE_2"
  echo "Terminating instances:$INSTANCES"
  aws ec2 terminate-instances --instance-ids $INSTANCES --region "$AWS_REGION" --output text 2>/dev/null || true
  echo "Waiting for instances to terminate..."
  aws ec2 wait instance-terminated --instance-ids $INSTANCES --region "$AWS_REGION" 2>/dev/null || true
fi

# --- 2. Delete ALB (listeners are deleted with the ALB) ---
if [ -n "$ALB_ARN" ]; then
  echo "Deleting ALB: $ALB_ARN"
  aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region "$AWS_REGION" --output text
fi

# --- 3. Delete Target Groups ---
if [ -n "$TG1_ARN" ]; then
  echo "Deleting target group 1"
  aws elbv2 delete-target-group --target-group-arn "$TG1_ARN" --region "$AWS_REGION" --output text 2>/dev/null || true
fi
if [ -n "$TG2_ARN" ]; then
  echo "Deleting target group 2"
  aws elbv2 delete-target-group --target-group-arn "$TG2_ARN" --region "$AWS_REGION" --output text 2>/dev/null || true
fi

# --- 4. Delete Security Groups (after ALB and instances are gone) ---
if [ -n "$ALB_SG" ]; then
  echo "Deleting ALB security group: $ALB_SG"
  for _ in 1 2 3 4 5; do
    aws ec2 delete-security-group --group-id "$ALB_SG" --region "$AWS_REGION" 2>/dev/null && break
    sleep 5
  done
fi
if [ -n "$SG_ID" ]; then
  echo "Deleting EC2 security group: $SG_ID"
  for _ in 1 2 3 4 5; do
    aws ec2 delete-security-group --group-id "$SG_ID" --region "$AWS_REGION" 2>/dev/null && break
    sleep 5
  done
fi

# --- 5. Delete ECR repositories ---
echo "Deleting ECR repositories (service1, service2)"
aws ecr delete-repository --repository-name service1 --force --region "$AWS_REGION" --output text 2>/dev/null || true
aws ecr delete-repository --repository-name service2 --force --region "$AWS_REGION" --output text 2>/dev/null || true

echo "Cleanup done. If you used Terraform bonus, run: cd terraform && terraform destroy"

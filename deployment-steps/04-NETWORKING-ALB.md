# Step D: Networking – Application Load Balancer

**Goal:** Create an Application Load Balancer with two Target Groups. Route `/service1` to service1 (port 5000) and `/service2` to service2 (port 5001). Both EC2 instances are in both target groups.

**Success criteria:** `curl http://<ALB-DNS>/service1` and `curl http://<ALB-DNS>/service2` return the expected JSON from each service.

---

## 1. Set variables

```bash
export AWS_REGION=us-east-1
export VPC_ID=vpc-xxxx          # from Step B
export SUBNET_ID=subnet-xxxx    # from Step B (use 2 subnets in 2 AZs for ALB if possible)
export SG_ID=sg-xxxx            # EC2 security group from Step B
export INSTANCE_1=i-xxxx        # from Step B
export INSTANCE_2=i-xxxx        # from Step B
```

For ALB you **must** use **2 subnets in different AZs**. List subnets and set both:

```bash
# List subnets in your VPC (pick two in different AZs)
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].[SubnetId,AvailabilityZone]' --output table --region $AWS_REGION
# Set both (replace with your subnet IDs)
export SUBNET_ID=subnet-xxxx   # first AZ
export SUBNET_ID_2=subnet-yyyy # second AZ (must be different from SUBNET_ID)
```

---

## 2. Create ALB security group

Allow inbound 80 (and 443 if you add HTTPS) from the internet. Outbound is allowed by default.

```bash
export ALB_SG=$(aws ec2 create-security-group \
  --group-name devops-alb-sg \
  --description "ALB for devops assessment" \
  --vpc-id $VPC_ID \
  --region $AWS_REGION \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $AWS_REGION
```

---

## 3. Create Application Load Balancer

Use two subnets (different AZs). If you have only one subnet, use it twice (ALB may still be created in some regions, but two AZs is best practice).

```bash
export ALB_ARN=$(aws elbv2 create-load-balancer \
  --name devops-alb \
  --type application \
  --scheme internet-facing \
  --security-groups $ALB_SG \
  --subnets $SUBNET_ID $SUBNET_ID_2 \
  --region $AWS_REGION \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

export ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text --region $AWS_REGION)
echo "ALB DNS: $ALB_DNS"
```

---

## 4. Create two Target Groups (one per service port)

**Target group 1 – service1 (port 5000):**

```bash
export TG1_ARN=$(aws elbv2 create-target-group \
  --name devops-service1-tg \
  --protocol HTTP \
  --port 5000 \
  --vpc-id $VPC_ID \
  --target-type instance \
  --health-check-path /health \
  --region $AWS_REGION \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
```

**Target group 2 – service2 (port 5001):**

```bash
export TG2_ARN=$(aws elbv2 create-target-group \
  --name devops-service2-tg \
  --protocol HTTP \
  --port 5001 \
  --vpc-id $VPC_ID \
  --target-type instance \
  --health-check-path /health \
  --region $AWS_REGION \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
```

---

## 5. Register both EC2 instances in both target groups

```bash
aws elbv2 register-targets --target-group-arn $TG1_ARN --targets Id=$INSTANCE_1 Id=$INSTANCE_2 --region $AWS_REGION
aws elbv2 register-targets --target-group-arn $TG2_ARN --targets Id=$INSTANCE_1 Id=$INSTANCE_2 --region $AWS_REGION
```

---

## 6. Allow ALB to reach EC2 on 5000 and 5001

EC2 security group must allow traffic from the ALB. Add rules to the **EC2** security group (`SG_ID`):

```bash
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 5000 --source-group $ALB_SG --region $AWS_REGION
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 5001 --source-group $ALB_SG --region $AWS_REGION
```

---

## 7. Create listener with path-based rules

Default action can be fixed-response or forward to one TG. Two rules: path `/service1*` → TG1, path `/service2*` → TG2.

```bash
# Listener: port 80, default action (optional) then rules
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=fixed-response,FixedResponseConfig='{StatusCode=404,ContentType="text/plain",MessageBody="Not Found"}' \
  --region $AWS_REGION

export LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query 'Listeners[0].ListenerArn' --output text --region $AWS_REGION)

# Rule 1: /service1 -> TG1 (priority 10)
aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN \
  --priority 10 \
  --conditions Field=path-pattern,Values='/service1','/service1/*' \
  --actions Type=forward,TargetGroupArn=$TG1_ARN \
  --region $AWS_REGION

# Rule 2: /service2 -> TG2 (priority 20)
aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN \
  --priority 20 \
  --conditions Field=path-pattern,Values='/service2','/service2/*' \
  --actions Type=forward,TargetGroupArn=$TG2_ARN \
  --region $AWS_REGION
```

---

## 8. Wait for targets to be healthy

```bash
aws elbv2 describe-target-health --target-group-arn $TG1_ARN --region $AWS_REGION
aws elbv2 describe-target-health --target-group-arn $TG2_ARN --region $AWS_REGION
```

Wait until State is `healthy` (can take 1–2 minutes).

---

## 9. Test

```bash
curl -s http://$ALB_DNS/service1
curl -s http://$ALB_DNS/service2
```

You should see JSON like `{"message":"Hello from Service 1",...}` and `{"message":"Hello from Service 2",...}`.

**Save:** `ALB_DNS` for the verification script.

Next: **05-VERIFICATION-SCRIPT.md** (automated health-check script).

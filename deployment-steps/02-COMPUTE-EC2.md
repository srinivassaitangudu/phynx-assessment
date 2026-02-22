# Step B: Compute Layer – EC2 Instances

**Goal:** Launch two t2.micro EC2 instances (Ubuntu 24.04) in the same VPC and AZ, and install Docker on them.

**Success criteria:** `docker info` works; `docker compose up -d` can run the services.

---

## 1. Set variables

```bash
export AWS_REGION=us-east-1   # same as in Step A
export KEY_NAME=your-key-name # name of an existing EC2 key pair in this region
```

If you don't have a key pair, create one in the AWS Console (EC2 → Key Pairs) or:

```bash
aws ec2 create-key-pair --key-name devops-assessment --query 'KeyMaterial' --output text > devops-assessment.pem
chmod 400 devops-assessment.pem
export KEY_NAME=devops-assessment
```

---

## 2. Get default VPC and subnets

Use one subnet for EC2. You will need **two subnets in different AZs** for the ALB in Step D, so note a second subnet.

```bash
export VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text --region $AWS_REGION)
# First subnet (for EC2)
export SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text --region $AWS_REGION)
# List all subnets (for ALB in Step D you need two in different AZs)
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].[SubnetId,AvailabilityZone]' --output table --region $AWS_REGION
echo "VPC: $VPC_ID  Subnet: $SUBNET_ID"
```

---

## 3. Create a security group (for EC2)

- Allow SSH (22) from your IP.
- Allow 80/443 from anywhere (for ALB later).
- Allow 5000 and 5001 from the same security group (so ALB in same SG can reach them; or we'll allow from ALB SG in Step D).

```bash
export MY_IP=$(curl -s https://checkip.amazonaws.com)
export SG_NAME=devops-ec2-sg

export SG_ID=$(aws ec2 create-security-group \
  --group-name $SG_NAME \
  --description "EC2 for devops assessment - SSH, HTTP, service ports" \
  --vpc-id $VPC_ID \
  --region $AWS_REGION \
  --query 'GroupId' --output text)

# SSH from your IP
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr ${MY_IP}/32 --region $AWS_REGION

# HTTP/HTTPS (for ALB listener; optional if you only use ALB on 80)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $AWS_REGION
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $AWS_REGION

# Service ports (5000, 5001) – allow from same SG (ALB will use this or its own SG)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 5000 --source-group $SG_ID --region $AWS_REGION
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 5001 --source-group $SG_ID --region $AWS_REGION
```

**Save:** `SG_ID` (you'll use it for the ALB target groups and possibly for the ALB itself).

---

## 4. Find Ubuntu 24.04 AMI ID

**Option A – describe-images** (only needs EC2 permissions):

```bash
export AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" "Name=state,Values=available" \
  --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text --region $AWS_REGION)
echo "AMI: $AMI_ID"
```

**Option B – SSM** (requires IAM policy with `ssm:GetParameters` on `/aws/service/canonical/*`):

```bash
export AMI_ID=$(aws ssm get-parameters \
  --names /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id \
  --query 'Parameters[0].Value' --output text --region $AWS_REGION)
echo "AMI: $AMI_ID"
```

If you see `AMI: None` with Option A, check that `AWS_REGION` is set. If your IAM user lacks SSM access, use Option A.

---

## 5. Launch two EC2 instances

```bash
aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --count 2 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=devops-service-host}]' \
  --region $AWS_REGION
```

---

## 6. Wait for instances to be running and get their IDs and IPs

```bash
sleep 30
export INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=devops-service-host" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].InstanceId' --output text --region $AWS_REGION)

export INSTANCE_1=$(echo $INSTANCE_IDS | awk '{print $1}')
export INSTANCE_2=$(echo $INSTANCE_IDS | awk '{print $2}')
echo "Instance 1: $INSTANCE_1  Instance 2: $INSTANCE_2"

# Get public IPs (for SSH)
export IP1=$(aws ec2 describe-instances --instance-ids $INSTANCE_1 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region $AWS_REGION)
export IP2=$(aws ec2 describe-instances --instance-ids $INSTANCE_2 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region $AWS_REGION)
echo "IP1: $IP1  IP2: $IP2"
```

---

## 7. Install Docker on both instances

Replace `ubuntu` and key path if you use a different user or key.

```bash
# Install Docker on instance 1
ssh -i ~/.ssh/$KEY_NAME.pem -o StrictHostKeyChecking=no ubuntu@$IP1 'sudo apt-get update -qq && sudo apt-get install -y -qq docker.io docker-compose-v2 && sudo usermod -aG docker ubuntu'

# Install Docker on instance 2
ssh -i ~/.ssh/$KEY_NAME.pem -o StrictHostKeyChecking=no ubuntu@$IP2 'sudo apt-get update -qq && sudo apt-get install -y -qq docker.io docker-compose-v2 && sudo usermod -aG docker ubuntu'
```

If the login user is `ec2-user` (Amazon Linux), use `ec2-user` instead of `ubuntu` and adjust package manager (`yum`/`dnf`) as needed. For Ubuntu 24.04 the user is usually `ubuntu`.

---

## 8. Verify Docker (after a short wait for group membership)

```bash
ssh -i ~/.ssh/$KEY_NAME.pem ubuntu@$IP1 'sudo docker info'
ssh -i ~/.ssh/$KEY_NAME.pem ubuntu@$IP2 'sudo docker info'
```

You should see Docker version and server info. If you get "permission denied" for `docker`, use `sudo docker` or log out and back in so `docker` group is applied.

**Save:** `IP1`, `IP2`, `INSTANCE_1`, `INSTANCE_2`, `SG_ID`, `SUBNET_ID`, `VPC_ID`.

Next: **03-ORCHESTRATION.md** (copy docker-compose, pull images, run services).

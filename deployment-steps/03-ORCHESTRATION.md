# Step C: Orchestration – Docker Compose on EC2

**Goal:** Place a docker-compose file on both EC2 instances that pulls images from ECR and runs both services on fixed ports (5000, 5001). Then verify with `curl .../health`.

**Success criteria:** `curl http://<instance-ip>:5000/health` and `:5001/health` return HTTP 200.

---

## 1. Set variables (from previous steps)

```bash
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
export IP1=1.2.3.4   # replace with your instance 1 public IP
export IP2=5.6.7.8   # replace with your instance 2 public IP
export KEY_NAME=your-key-name
```

---

## 2. Use the EC2-ready docker-compose file

The repo already has **`servers/docker-compose-ec2.yml`**, which uses ECR image URIs (no `build:`). You must replace the placeholders with your ECR host.

**Option A – sed (from repo root):**

```bash
cd /path/to/interview-repo/servers
sed -e "s/YOUR_ACCOUNT.dkr.ecr.YOUR_REGION.amazonaws.com/$ECR_URI/g" docker-compose-ec2.yml > docker-compose-ec2-filled.yml
# Use docker-compose-ec2-filled.yml when copying to EC2
```

**Option B – edit by hand:**  
Open `servers/docker-compose-ec2.yml` and replace `YOUR_ACCOUNT` with your AWS account ID and `YOUR_REGION` with your region (e.g. `123456789012.dkr.ecr.us-east-1.amazonaws.com`). Save as-is or as another file to copy to EC2.

---

## 3. Ensure EC2 instances can pull from ECR

**Option A – Pipe ECR password from your laptop (no AWS CLI on instance):**

Run `aws` locally and pipe the token into the instance. No IAM role or AWS CLI on EC2 needed.

```bash
aws ecr get-login-password --region $AWS_REGION | ssh -i ~/.ssh/$KEY_NAME.pem ubuntu@$IP1 "sudo docker login --username AWS --password-stdin $ECR_URI"
aws ecr get-login-password --region $AWS_REGION | ssh -i ~/.ssh/$KEY_NAME.pem ubuntu@$IP2 "sudo docker login --username AWS --password-stdin $ECR_URI"
```

You should see `Login Succeeded` for each.

**Option B – IAM instance profile + AWS CLI on instance:**  
Attach an IAM role with `AmazonEC2ContainerRegistryReadOnly` to both instances, install AWS CLI on the instances, then run the login **on** the instance (e.g. via SSH). Use this if you prefer instance-based auth for ongoing pulls.

**If you see** `no matching manifest for linux/amd64` **:** The images in ECR were built for another architecture (e.g. arm64 on Apple Silicon). Rebuild for EC2 with `docker buildx build --platform linux/amd64 ...` and push again (see **01-IMAGE-PUSH-ECR.md** step 4), then re-run pull on the instances.

---

## 4. Copy docker-compose file to both instances

From your machine, from the directory that contains your **filled** compose file (with real ECR URIs), e.g. `servers/docker-compose-ec2-filled.yml` or the edited `docker-compose-ec2.yml`:

```bash
cd /path/to/interview-repo/servers
scp -i ~/.ssh/$KEY_NAME.pem docker-compose-ec2-filled.yml ubuntu@$IP1:~/docker-compose.yml
scp -i ~/.ssh/$KEY_NAME.pem docker-compose-ec2-filled.yml ubuntu@$IP2:~/docker-compose.yml
```

---

## 5. On each instance: pull and run

**Instance 1:**

```bash
ssh -i ~/.ssh/$KEY_NAME.pem ubuntu@$IP1 'cd ~ && sudo docker compose -f docker-compose.yml pull && sudo docker compose -f docker-compose.yml up -d'
```

**Instance 2:**

```bash
ssh -i ~/.ssh/$KEY_NAME.pem ubuntu@$IP2 'cd ~ && sudo docker compose -f docker-compose.yml pull && sudo docker compose -f docker-compose.yml up -d'
```

---

## 6. Verify containers and health

On each instance:

```bash
ssh -i ~/.ssh/$KEY_NAME.pem ubuntu@$IP1 'sudo docker ps'
ssh -i ~/.ssh/$KEY_NAME.pem ubuntu@$IP2 'sudo docker ps'
```

You should see `service1` and `service2` running. Then from your laptop:

```bash
curl -s http://$IP1:5000/health
curl -s http://$IP1:5001/health
curl -s http://$IP2:5000/health
curl -s http://$IP2:5001/health
```

Each should return something like `{"status":"healthy"}` with HTTP 200. If curl fails, check security group: ports 5000 and 5001 must be allowed from your IP (or from the ALB security group once you create it).

**Save:** `IP1`, `IP2` (and instance IDs) for the next step (ALB target registration).

Next: **04-NETWORKING-ALB.md** (ALB + path-based routing).

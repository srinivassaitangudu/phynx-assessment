# Step A: Image Push to Amazon ECR

**Goal:** Tag and push the two Docker images to Amazon ECR so you can pull them on EC2.

**Success criteria:** `docker pull <ECR-URI>` retrieves the image with the correct digest.

---

## 1. Set your AWS region and account ID

```bash
# Replace with your region (e.g. us-east-1, ap-northeast-2)
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

---

## 2. Create ECR repositories

```bash
aws ecr create-repository --repository-name service1 --region $AWS_REGION
aws ecr create-repository --repository-name service2 --region $AWS_REGION
```

If they already exist, you'll see an error; that's fine.

---

## 3. Log in to ECR (so Docker can push)

```bash
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

You should see: `Login Succeeded`.

---

## 4. Build images for linux/amd64 (required if you're on macOS/ARM)

From the **interview-repo** root:

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd servers
```

Build both images for the platform EC2 uses:

```bash
docker buildx build --platform linux/amd64 -t service1:latest ./service1 --load
docker buildx build --platform linux/amd64 -t service2:latest ./service2 --load
```

If you're on Linux x86_64 you can use:

```bash
docker build -t service1:latest ./service1
docker build -t service2:latest ./service2
```

---

## 5. Tag images with ECR URIs

**Use the same terminal/shell where you set `AWS_REGION` and `AWS_ACCOUNT_ID` in step 1.** If you opened a new terminal, run step 1 again, then:

```bash
export ECR_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
echo "ECR_URI=$ECR_URI"   # should print e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com

docker tag service1:latest $ECR_URI/service1:latest
docker tag service2:latest $ECR_URI/service2:latest
```

**If you see** `"/service1:latest" is not a valid repository/tag: invalid reference format` **:** `$ECR_URI` is empty. Set the variables (step 1 + `export ECR_URI=...` above) in the same shell and try again.

---

## 6. Push to ECR

```bash
docker push $ECR_URI/service1:latest
docker push $ECR_URI/service2:latest
```

---

## 7. Verify

```bash
# Get repository URIs
aws ecr describe-repositories --repository-names service1 service2 --region $AWS_REGION --query 'repositories[*].[repositoryName,repositoryUri]' --output table

# Pull and confirm digest (replace <uri> with the URI from above)
docker pull $ECR_URI/service1:latest
docker pull $ECR_URI/service2:latest
docker images --digests | grep ecr
```

**Save these for later:**  
- `$ECR_URI/service1:latest`  
- `$ECR_URI/service2:latest`  
- `$AWS_REGION` and `$AWS_ACCOUNT_ID`

Next: **02-COMPUTE-EC2.md** (launch EC2 and install Docker).

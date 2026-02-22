# Before You Start: Create AWS Account and Setup

You don’t have an AWS account yet. Do this **once** before running the assessment steps (01 → 06). After this, you’ll use **01-IMAGE-PUSH-ECR.md** as Step A.

---

## Phase 0 – What to do after (or while) creating the account

| Order | Task | Details below |
|-------|------|----------------|
| 1 | Create AWS account | Sign up, verify email, add payment method |
| 2 | Secure the root user | Enable MFA, don’t use root for daily CLI |
| 3 | Create IAM user for CLI (recommended) | Or use root access keys only if short on time |
| 4 | Install AWS CLI | On your Mac/Linux/Windows |
| 5 | Configure AWS CLI | `aws configure` with access key and region |
| 6 | Verify | `aws sts get-caller-identity` works |
| 7 | Start assessment | Go to **01-IMAGE-PUSH-ECR.md** |

---

## 1. Create an AWS account

1. Go to **https://aws.amazon.com** and choose **Create an AWS Account**.
2. Use a valid **email** and an **account name** (e.g. “devops-assessment”).
3. Choose **Personal** or **Professional**; fill in contact and address.
4. Add a **payment method** (card). You will not be charged without your explicit usage; the assessment typically stays under the free tier or low cost (~\$30; reimbursement may be available per the problem statement).
5. Verify your identity (phone/ID if asked).
6. Choose a **Support plan** (e.g. Free).
7. Wait for the account to be active and sign in to the **AWS Management Console**.

---

## 2. Secure the root user (recommended)

- In the console: **Account** (top right) → **Security credentials**.
- **Turn on MFA** for the root user (e.g. authenticator app).
- Avoid using the root user for day-to-day work. Use an **IAM user** with limited permissions for the assessment.

---

## 3. Create an IAM user for the assessment (recommended)

1. In the console go to **IAM** → **Users** → **Create user**.
2. User name: e.g. `devops-assessment`. Enable **Programmatic access** (access key for CLI).
3. **Permissions:** Attach policies. For a quick, time-boxed assessment the problem statement allows:
   - **AmazonEC2ContainerRegistryFullAccess** (for ECR), and
   - **AmazonEC2FullAccess** (for EC2, VPC, security groups, etc.).
   For production you’d use more restrictive, custom policies.
4. Create the user, then **Create access key** (use “CLI” or “Command Line Interface”).
5. **Save the Access Key ID and Secret Access Key** somewhere safe (you won’t see the secret again). You’ll use them in **Step 5**.

Alternatively you can use the root user’s access key for the assessment if you’re very short on time (not recommended long-term).

---

## 4. Install AWS CLI

- **macOS (Homebrew):**  
  `brew install awscli`
- **Linux:**  
  See https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html (e.g. package manager or official installer).
- **Windows:**  
  MSI installer from the same link, or `winget install Amazon.AWSCLI`.

Check:

```bash
aws --version
```

---

## 5. Configure AWS CLI

Run:

```bash
aws configure
```

When prompted:

- **AWS Access Key ID:** paste the access key from Step 3 (or root).
- **AWS Secret Access Key:** paste the secret key.
- **Default region name:** choose one, e.g. `us-east-1` or `ap-northeast-2` (use the same region in all steps).
- **Default output format:** `json` (or leave blank).

Credentials are stored under `~/.aws/credentials` and region under `~/.aws/config`.

---

## 6. Verify setup

```bash
aws sts get-caller-identity
```

You should see your **Account ID**, **User ARN**, and **UserId**. Also confirm Docker is installed:

```bash
docker --version
docker compose version
```

---

## 7. Cost and cleanup

- The assessment can incur **small AWS costs** (often under \$30). The problem statement may allow reimbursement (e.g. up to \$35); keep receipts/screenshots if you claim.
- After you’re done, **tear down all resources** as in **06-BONUS-CLEANUP.md** so you don’t keep paying.

---

## Next step

Once the account is created, CLI is configured, and `aws sts get-caller-identity` works:

**Start the assessment with 01-IMAGE-PUSH-ECR.md** (Step A: push Docker images to ECR).

# How to Submit This Assessment

Submit **either** a **public GitHub repository** **or** a **downloadable ZIP**, as per the problem statement.

---

## Option 1: Public GitHub repository

1. **Create a repo** on GitHub (e.g. `devops-assessment`). Keep it **public**.
2. **Remove secrets** from the repo:
   - Do **not** commit `terraform/terraform.tfvars` if it contains your real account IDs (use `terraform.tfvars.example` only, with placeholders).
   - Ensure no AWS keys, passwords, or private IPs are in committed files.
3. **Push your code:**
   ```bash
   cd interview-repo
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git add .
   git commit -m "DevOps assessment submission"
   git push -u origin main
   ```
4. **Add screenshots** (see checklist below): either commit them in a `screenshots/` or `docs/` folder, or host elsewhere and add links in README.
5. **Fill CLEANUP_CONFIRMATION.md** after you tear down AWS resources (date, region, checklist).
6. **Share the repo URL** with the assessor.

---

## Option 2: Downloadable ZIP

1. **Clean the repo** (no secrets, no `.git` if you prefer):
   - Remove or redact `terraform/terraform.tfvars` (keep only `.example`).
   - Run cleanup and fill `CLEANUP_CONFIRMATION.md`.
2. **Add screenshots** into a folder (e.g. `screenshots/`) in the repo.
3. **Create the ZIP** from the repo root:
   ```bash
   cd /path/to/interview-repo
   zip -r ../devops-assessment-submission.zip . -x "*.git*" -x "*terraform.tfvars" -x ".DS_Store"
   ```
4. **Upload** `devops-assessment-submission.zip` to the place the assessor specifies (link, form, etc.).

---

## Deliverables checklist (from problem statement)

Before submitting, confirm you have:

| # | Deliverable | Where in this repo |
|---|-------------|--------------------|
| 1 | **README.md** with architecture, region, deployment steps, verification script instructions, and **diagram** | `README.md` (see “Architecture” and “Deployment” sections) |
| 2 | **docker-compose.yml** used on EC2 | `docker-compose.yml` at repo root (EC2 version; replace ECR placeholder) |
| 3 | **verify_endpoints.sh** or verify_endpoints.py | `verify_endpoints.sh` |
| 4 | **Screenshots / command output**: ECR images, docker ps (both instances), ALB DNS + curl, (Bonus) ASG evidence | Add in `screenshots/` or link in README |
| 5 | **Cleanup confirmation** | `CLEANUP_CONFIRMATION.md` (fill after teardown) |
| 6 | **(Optional) Terraform** | `terraform/` |

---

## Screenshots to capture (before cleanup)

1. **ECR:** AWS Console → ECR → Repositories → `service1` and `service2` (list of images).
2. **docker ps:** SSH to each EC2 instance and run `sudo docker ps`; capture output for both.
3. **ALB + curl:** Terminal showing `curl http://<ALB-DNS>/service1` and `curl http://<ALB-DNS>/service2` with responses.
4. **(Bonus)** **ASG:** EC2 → Auto Scaling Groups → Activity, or CloudWatch → CPU metric for the ASG (if you did Terraform bonus).

Save these as images (e.g. `screenshots/01-ecr.png`, `02-docker-ps-instance1.png`, etc.) or paste command output into a doc and add to the repo or ZIP.

---

## After submission

- Run **cleanup** (`scripts/cleanup.sh` and, if used, `terraform destroy`) so you don’t incur ongoing AWS cost.
- Fill **CLEANUP_CONFIRMATION.md** and, if you already submitted, add a note in README or resubmit the ZIP with the updated confirmation.

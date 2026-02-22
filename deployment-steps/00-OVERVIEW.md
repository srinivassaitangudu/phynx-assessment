# Deployment Steps – Overview

This folder contains **step-by-step instructions** for the DevOps interview assessment: deploying two containerized Flask services to AWS (ECR → EC2 → ALB) and verifying them.

**Don’t have an AWS account yet?** Do **Phase 0** first: **`00-PREREQUISITES-AWS-ACCOUNT-SETUP.md`** (create account, IAM user, install and configure AWS CLI). Then run the steps below.

**Want to practice without AWS?** Use **`00-WITHOUT-AWS-PLAN.md`** and the **01a → 06a** steps (local registry, nginx load balancer).

---

## Order of steps (with AWS)

| Phase | File | What you do |
|-------|------|-------------|
| **0** | `00-PREREQUISITES-AWS-ACCOUNT-SETUP.md` | Create AWS account, IAM user, install & configure AWS CLI |
| **A** | `01-IMAGE-PUSH-ECR.md` | Push Docker images to Amazon ECR |
| **B** | `02-COMPUTE-EC2.md` | Launch 2× EC2 instances, install Docker |
| **C** | `03-ORCHESTRATION.md` | Put docker-compose on EC2, pull images, run services |
| **D** | `04-NETWORKING-ALB.md` | Create ALB + Target Groups, path-based routing |
| **E** | `05-VERIFICATION-SCRIPT.md` | Write and run the health-check script |
| **F** | `06-BONUS-CLEANUP.md` | Optional Terraform/ASG; then cleanup all resources |

Do **Phase 0 once**, then **A → B → C → D → E** in order. Step F is optional for bonus; cleanup is required.

## Prerequisites (after Phase 0)

- **AWS CLI** installed and configured (`aws configure`).
- **Docker** (and Docker Compose) installed locally.
- **AWS region** chosen (e.g. `us-east-1`, `ap-northeast-2`). Use the same region in all steps.
- From repo root, all paths are relative to `interview-repo/`.

## Quick reference

- **Service 1**: port **5000**, routes `/`, `/service1`, `/health`.
- **Service 2**: port **5001**, routes `/`, `/service2`, `/health`.
- **ECR repos**: `service1`, `service2`.
- **Success**: `curl http://<ALB-DNS>/service1` and `/service2` return JSON; verification script exits 0.

**Start:** If you already have an account and CLI configured → **01-IMAGE-PUSH-ECR.md**. If not → **00-PREREQUISITES-AWS-ACCOUNT-SETUP.md**.

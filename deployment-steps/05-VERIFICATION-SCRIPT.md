# Step E: Verification Script

**Goal:** Implement a Bash or Python script that tests all endpoints (and optionally ECR) and exits with **0** only when all checks pass, **non-zero** on any failure.

**Success criteria:** Script exits cleanly (0) when all checks pass.

---

## 1. What the script must test (from README)

- `curl -s http://$ALB_DNS/service1` → expect Service 1 response
- `curl -s http://$ALB_DNS/service2` → expect Service 2 response
- (Optional) ECR: `aws ecr describe-repositories --repository-names service1 service2` and repository URIs

---

## 2. Where to put the script

Create in the repo root:

- **Bash:** `interview-repo/verify_endpoints.sh`
- **Python:** `interview-repo/verify_endpoints.py`

---

## 3. How to run it

- **Bash:**  
  `ALB_DNS=<your-alb-dns> ./verify_endpoints.sh`  
  or export `ALB_DNS` then run `./verify_endpoints.sh`.

- **Python:**  
  `ALB_DNS=<your-alb-dns> python3 verify_endpoints.py`  
  or pass ALB DNS as first argument: `python3 verify_endpoints.py <ALB_DNS>`.

---

## 4. Exact checks to implement

1. **ALB /service1**  
   - `GET http://$ALB_DNS/service1`  
   - Expect HTTP 200 and body containing `"Hello from Service 1"` or `"service1"` / `"Service 1"`.

2. **ALB /service2**  
   - `GET http://$ALB_DNS/service2`  
   - Expect HTTP 200 and body containing `"Hello from Service 2"` or `"service2"` / `"Service 2"`.

3. **(Optional) ECR**  
   - `aws ecr describe-repositories --repository-names service1 --query 'repositories[0].repositoryUri' --output text`  
   - `aws ecr describe-repositories --repository-names service2 --query 'repositories[0].repositoryUri' --output text`  
   - Script can just run these and check exit code (and optionally print URIs).

4. **Exit code**  
   - If any check fails: exit non-zero (e.g. 1).  
   - If all pass: exit 0.

---

## 5. Implementation notes

- **Bash:** Use `curl -s -o /dev/null -w "%{http_code}"` for status; `curl -s` body can be piped to `grep -q "Service 1"` etc.
- **Python:** Use `urllib.request` or `requests`; check `response.status_code == 200` and substring in `response.text`; for ECR use `subprocess.run(["aws", "ecr", ...])` and check `returncode`.
- Prefer **no trailing slash** on ALB URL (e.g. `http://$ALB_DNS/service1`) unless you added a rule for `/service1/`.
- If `ALB_DNS` is unset, script should print a short usage and exit non-zero.

---

## 6. Example invocation after deployment

```bash
cd /path/to/interview-repo
export ALB_DNS=devops-alb-1234567890.us-east-1.elb.amazonaws.com
./verify_endpoints.sh
echo "Exit code: $?"
```

Or with Python:

```bash
python3 verify_endpoints.py $ALB_DNS
echo "Exit code: $?"
```

Use the script in your deliverables and mention in the README how to run it (as in **00-OVERVIEW.md**).

Next: **06-BONUS-CLEANUP.md** (optional Terraform/ASG + cleanup).

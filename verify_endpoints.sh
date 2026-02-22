#!/usr/bin/env bash
# Verification script for devops assessment: tests /service1 and /service2.
# Exit 0 if all checks pass, 1 otherwise.
#
# Usage:
#   ALB_DNS=your-alb-dns.us-east-1.elb.amazonaws.com ./verify_endpoints.sh
#   or set BASE_URL below and run: ./verify_endpoints.sh

set -e

# --- Set your ALB DNS or base URL: use env ALB_DNS / BASE_URL, or edit the line below ---
if [ -n "$ALB_DNS" ]; then
  BASE_URL="http://$ALB_DNS"
elif [ -n "$BASE_URL" ]; then
  : # use env BASE_URL as-is
else
  # Add your ALB DNS below (no http:// needed) to run with: ./verify_endpoints.sh
  ALB_DNS="devops-alb-1103791012.us-east-1.elb.amazonaws.com"   # e.g. ALB_DNS="devops-alb-1234567890.us-east-1.elb.amazonaws.com"
  BASE_URL="${ALB_DNS:+http://$ALB_DNS}"
fi

if [ -z "$BASE_URL" ]; then
  echo "Usage: ALB_DNS=<alb-dns> ./verify_endpoints.sh"
  echo "   or: BASE_URL=http://<host> ./verify_endpoints.sh"
  echo "   or set BASE_URL at the top of this script."
  exit 1
fi

# Normalize: ensure scheme
case "$BASE_URL" in
  http://*|https://*) ;;
  *) BASE_URL="http://$BASE_URL" ;;
esac

FAILED=0

# --- Check /service1 ---
echo -n "Checking $BASE_URL/service1 ... "
HTTP_CODE=$(curl -s -o /tmp/verify_service1.json -w "%{http_code}" "$BASE_URL/service1")
if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL (HTTP $HTTP_CODE)"
  FAILED=1
else
  if grep -q "Service 1" /tmp/verify_service1.json 2>/dev/null; then
    echo "OK"
  else
    echo "FAIL (unexpected body)"
    FAILED=1
  fi
fi

# --- Check /service2 ---
echo -n "Checking $BASE_URL/service2 ... "
HTTP_CODE=$(curl -s -o /tmp/verify_service2.json -w "%{http_code}" "$BASE_URL/service2")
if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL (HTTP $HTTP_CODE)"
  FAILED=1
else
  if grep -q "Service 2" /tmp/verify_service2.json 2>/dev/null; then
    echo "OK"
  else
    echo "FAIL (unexpected body)"
    FAILED=1
  fi
fi

# --- Optional: ECR (set VERIFY_ECR=1 to enable) ---
if [ "${VERIFY_ECR:-0}" = "1" ]; then
  echo -n "Checking ECR repositories ... "
  if aws ecr describe-repositories --repository-names service1 service2 --query 'repositories[*].repositoryUri' --output text &>/dev/null; then
    echo "OK"
  else
    echo "FAIL (aws ecr describe-repositories failed)"
    FAILED=1
  fi
fi

rm -f /tmp/verify_service1.json /tmp/verify_service2.json

if [ $FAILED -eq 1 ]; then
  exit 1
fi
echo "All checks passed."
exit 0

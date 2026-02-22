#!/bin/bash
# Bonus: Launch Template user-data — install Docker, ECR login, run docker-compose.
set -e
export AWS_REGION="${aws_region}"
export ECR_URI="${ecr_uri}"

# Install Docker (Ubuntu 24.04)
apt-get update -qq && apt-get install -y -qq ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update -qq && apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
usermod -aG docker ubuntu

# AWS CLI for ECR login (instance profile must have ECR read)
apt-get install -y -qq awscli || true

# Write docker-compose.yml (base64 payload from Terraform)
mkdir -p /home/ubuntu
echo '${docker_compose_b64}' | base64 -d > /home/ubuntu/docker-compose.yml
chown ubuntu:ubuntu /home/ubuntu/docker-compose.yml

# ECR login and start services as ubuntu (so docker socket is used)
sudo -u ubuntu bash -c "aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI"
sudo -u ubuntu bash -c "cd /home/ubuntu && docker compose -f docker-compose.yml pull && docker compose -f docker-compose.yml up -d"

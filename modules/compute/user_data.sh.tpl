#!/bin/bash
# Runs once at first boot. Any failure stops the script immediately (set -e),
# which shows up in /var/log/cloud-init-output.log for debugging.
set -euo pipefail

# Amazon Linux 2023 ships with the AWS CLI but not Docker.
dnf install -y docker
systemctl enable --now docker

# Log in to ECR with a short-lived token from the instance role.
# No password is stored anywhere on the instance.
aws ecr get-login-password --region "${region}" | docker login --username AWS --password-stdin "${registry}"

docker pull "${image}"

# --restart unless-stopped restarts the app after a crash or a reboot.
docker run -d --name app --restart unless-stopped -p "${app_port}:8080" "${image}"

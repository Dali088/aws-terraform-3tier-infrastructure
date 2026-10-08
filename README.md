# AWS Terraform 3-Tier Infrastructure

Production-style AWS environment built entirely with Terraform: VPC, load-balanced Auto Scaling web tier, private RDS database, CI/CD with GitHub Actions (OIDC), and CloudWatch monitoring.

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)
![Status](https://img.shields.io/badge/status-in%20progress-orange)

> **Status:** under active development as a 7-day learning project. Sections marked *(planned)* are not built yet. Progress is tracked on the [project board](https://github.com/Dali088/aws-terraform-3tier-infrastructure/projects).

## Architecture *(planned)*

A diagram will be added on Day 2, once the network layer exists.

## Features

Done:

- Terraform provider configured with default tags (Project, Environment, ManagedBy)
- Pre-commit hooks: terraform fmt/validate, tflint, checkov, gitleaks
- Branch protection on `main`, with all changes going through pull requests

Planned:

- VPC with public and private subnets across 2 availability zones
- Remote state in S3 with locking
- Containerized web app on an Application Load Balancer and Auto Scaling Group
- RDS database in a private subnet
- Least-privilege IAM and security groups
- GitHub Actions pipeline with OIDC authentication
- CloudWatch alarms and an AWS billing alert

## Tech stack

Terraform, AWS (VPC, EC2, ALB, RDS, IAM, S3, CloudWatch), Docker, GitHub Actions, pre-commit, tflint, checkov, gitleaks.

## Prerequisites *(planned)*

- An AWS account and an IAM user with MFA
- Terraform 1.9 or newer
- AWS CLI v2
- Git and pre-commit

## Deployment *(planned)*

Step-by-step instructions will be added as the modules are built.

## Estimated cost *(planned)*

Details will go in `docs/cost.md`. The environment is designed to be destroyed after each work session with `terraform destroy`.

## Project structure

```
.
├── environments/
│   └── dev/            # root configuration for the dev environment
├── docs/               # architecture, decisions, runbook, lessons learned
├── .pre-commit-config.yaml
├── CONTRIBUTING.md
└── LICENSE
```

## Security notes

- No credentials are stored in this repository. Secrets are blocked by `.gitignore`, pre-commit hooks and gitleaks.
- Terraform state files are excluded from Git.
- More detail will be added in `docs/security.md`.

## Lessons learned

See [docs/lessons-learned.md](docs/lessons-learned.md).

## Future improvements

To be added at the end of the project.

## Contact

- GitHub: [Dali088](https://github.com/YOUR-USERNAME)
- LinkedIn: *(add your profile link)*

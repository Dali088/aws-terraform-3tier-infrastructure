# ADR-003: Run the app as containers on EC2 behind an ALB and Auto Scaling Group

- **Status:** Accepted
- **Date:** 2026-11-03
- **Deciders:** Dali

## Context

The app must be reachable through a load balancer, run in private subnets, scale across two availability zones, and be deployable from an image in ECR. The project is for learning infrastructure as code, so the compute model should show core AWS building blocks.

## Options considered

| Option | Pros | Cons |
|---|---|---|
| Bare install on EC2 (no container) | Simplest | Configuration drift, harder rollbacks, no image artifact |
| Containers on EC2 via ASG (chosen) | Shows container packaging, ALB, ASG and launch templates | More moving parts than a managed service |
| ECS on Fargate | No servers to manage, less boot logic | Hides the networking and instance layers this project teaches |
| EKS | Industry standard for orchestration | Far too heavy and expensive for this project |
| Lambda | Zero servers | Different model, not a long-running web server |

## Decision

Run the Flask container on EC2 instances in an Auto Scaling Group across private subnets, with an ALB in public subnets. Each instance pulls the image from ECR at boot using its instance role and starts the container with a restart policy.

## Consequences

- **Positive:** the design uses the core building blocks, shows ALB health checks and replacement, and keeps instances private.
- **Positive:** no SSH; access is through Session Manager.
- **Negative:** the boot script is a manual deployment mechanism. A new image version needs a new launch template version, or instances must be replaced. Rolling updates are a future improvement.
- **Negative:** each instance runs its own container with no orchestration. Fargate or ECS would handle this for production.
- **Cost:** the ALB and instances bill hourly, so the stack is destroyed after each session.
- **Follow-up:** Day 5 CI/CD will build and push images. Revisit this ADR if the deployment model changes to ECS or Kubernetes.

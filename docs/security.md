# Security

This document explains the security design of the dev environment: who can reach what, which permissions are granted, what is encrypted, and what risks remain.

## Layers of defense

| Layer | Control |
|---|---|
| Network | Private subnets with no route to the internet gateway. Public subnets hold only the load balancer and the NAT gateway. |
| Network filter | Security groups: the ALB accepts HTTP from anywhere, and the app accepts traffic only from the ALB security group. |
| Identity | An IAM role for the instances, limited to pulling one ECR repository and Session Manager access. |
| Transport | IMDSv2 required on instances. TLS required for state bucket access. |
| Data at rest | Encrypted EBS root volumes, encrypted state bucket (AES256), encrypted ECR images (AES256). |
| Secrets | No credentials in Git. Secrets are blocked by `.gitignore`, pre-commit hooks, and gitleaks. |
| Delivery | Images are scanned on push, and the tag is immutable so a release cannot be replaced. |

## IAM design

| Role | Permissions | Why |
|---|---|---|
| Instance role (`app`) | `ecr:GetAuthorizationToken` on `*`, pull actions on one repository, `AmazonSSMManagedInstanceCore` | Pull the image and open a shell through Session Manager. Nothing else. |
| Developer (`Dali` IAM user) | `AdministratorAccess` | Learning account. Too broad for production; to be narrowed later. |
| Root user | Not used for daily work, MFA enabled | Only for billing and account recovery. |

`ecr:GetAuthorizationToken` must use `*` because AWS does not support resource scoping for it. Pull actions are limited to one repository ARN.

## Security group rules

| Group | Direction | Port | Source or destination | Purpose |
|---|---|---|---|---|
| ALB | Inbound | 80 | 0.0.0.0/0 | Public HTTP |
| ALB | Outbound | 8080 | App group | Forward to the app |
| App | Inbound | 8080 | ALB group | Only the load balancer |
| App | Outbound | 443 | 0.0.0.0/0 | ECR and AWS APIs through NAT |

**Known gap:** AWS adds an allow-all outbound rule to new security groups. Terraform creates the egress rules above but does not remove the default rule. Outbound restriction is a hardening item.

## Encryption

| Item | Encryption | Notes |
|---|---|---|
| Terraform state (S3) | AES256 at rest, TLS-only policy | Versioned, public access blocked |
| EBS root volumes | Encrypted | Deleted with the instance |
| ECR images | AES256 | Customer KMS key skipped, see below |

## Accepted risks and skipped checks

Each skip is recorded in code with a reason. The main ones:

| Check | Reason |
|---|---|
| CKV_AWS_260 | The ALB must accept public HTTP. HTTPS is a stretch goal. |
| CKV_AWS_136 | AES256 is enabled. A KMS key costs about $1/month for a learning project. |
| CKV2_AWS_5 | Security groups are built before the resources that attach them. |
| CKV2_AWS_11 | VPC flow logs are deferred to the Day 6 CloudWatch work. |
| CKV2_AWS_19 | A NAT gateway attaches its own EIP, which the scanner cannot see. |
| CKV_AWS_150, CKV_AWS_91, CKV_AWS_2 | Deletion protection, access logs, and HTTPS are deferred for a learning environment. |
| CKV2_AWS_20 | HTTP is not redirected to HTTPS. HTTPS with an ACM certificate is a stretch upgrade. |
| CKV2_AWS_28 | No WAF. It bills per request and is out of scope. |
| CKV_AWS_378 | ALB-to-instance traffic stays inside the private VPC. |
| CKV_AWS_103 | TLS policies apply only to HTTPS listeners. This listener is HTTP by design. |

## Threat considerations

- **Public app exposure:** only port 80 on the ALB is public. Instances are not reachable from the internet.
- **Stolen instance credentials:** IMDSv2 blocks the common SSRF route to instance role credentials. The role is also narrow.
- **Image tampering:** immutable tags and scan-on-push. Digest pinning is a future improvement.
- **Leaked state:** state is encrypted, private, and never committed.
- **Docker group membership:** on the developer laptop, membership in the `docker` group is effectively root access. Acceptable for a personal learning machine.

## Known gaps

- The default security group egress rule is still present. Restricting it is a hardening item.
- The module-level lock file `modules/compute/.terraform.lock.hcl` should be removed. The root lock file in `environments/dev` controls provider versions. Tracked for a cleanup PR.

## Future hardening

- Restrict the default security group egress
- HTTPS with an ACM certificate, which also resolves the ALB redirect, TLS policy, and listener checks
- Access logs and VPC flow logs
- Narrow the developer IAM policy
- Pin image deployments by digest
- Add WAF for the public ALB

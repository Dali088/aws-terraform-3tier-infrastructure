# ADR-001: NAT gateway for private subnet outbound access

- **Status:** Accepted
- **Date:** 2026-10-31
- **Deciders:** Dali

## Context

Private subnets hold the application servers and the database. They must
never be reachable from the internet, but the application needs outbound
access to install packages, pull container images from ECR, and call AWS
APIs. The design must also control cost, because this is a learning account
on the AWS Free plan.

## Options considered

| Option | Outbound access | Cost | Notes |
|---|---|---|---|
| No NAT | None | $0 | Private instances cannot pull images or updates. Breaks Day 3. |
| NAT gateway (one, in one AZ) | Yes | Roughly $1+/day while running | Managed by AWS, highly available within its AZ |
| NAT gateway per AZ | Yes, resilient to AZ failure | About double the above | Production choice, too expensive for learning |
| NAT instance (EC2 you manage) | Yes | Small EC2 cost | Cheaper, but you patch and scale it yourself |
| VPC endpoints (ECR, S3, etc.) | Only to AWS services | Interface endpoints are billed hourly | Good for AWS-only traffic, does not cover general internet |

## Decision

Use **one NAT gateway in `public-a`**, controlled by the `enable_nat_gateway`
variable. Destroy it at the end of every working session.

## Consequences

- **Positive:** private instances get outbound access with no inbound exposure,
  and the setup is managed by AWS.
- **Negative:** if AZ `a` fails, private subnets in AZ `b` lose outbound access.
  This is accepted for a learning project and is the first thing to change for production.
- **Cost:** the NAT gateway and its Elastic IP are billed while they exist, so
  they must be destroyed with `terraform destroy` after each session.
- **Follow-up:** Day 3 may add VPC endpoints for ECR to reduce NAT traffic.
  Revisit this ADR if the design changes.

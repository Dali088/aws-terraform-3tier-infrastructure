# ADR-002: S3 remote state with native locking

- **Status:** Accepted
- **Date:** 2026-10-31
- **Deciders:** Dali

## Context

Terraform state holds the mapping between code and real AWS resources, and it can contain secrets. A state file on one laptop is lost if the laptop is lost, and it cannot be shared with CI.

## Options considered

| Option | Pros | Cons |
|---|---|---|
| Local state | Simplest | Lost with the laptop, no sharing, no locking |
| S3 + DynamoDB lock table | Long-established pattern | Extra resource to manage |
| S3 with native lock file (`use_lockfile`) | No extra resource, locking included, Terraform 1.10+ | Requires a recent Terraform version |
| Terraform Cloud | Managed locking and UI | External service, more to learn |

## Decision

Store state in an encrypted, versioned S3 bucket created by a separate `bootstrap/` configuration, and use native S3 locking (`use_lockfile = true`). Require Terraform 1.10 or newer.

## Consequences

- **Positive:** state survives a lost laptop, old versions are recoverable, and two runs cannot change state at once.
- **Positive:** no DynamoDB table, which means one fewer resource and no extra cost.
- **Negative:** the bootstrap state stays on the laptop, because the bucket cannot store its own state. It must not be deleted.
- **Security:** the bucket blocks public access, enforces TLS, and uses AES256 encryption. The bootstrap bucket has `prevent_destroy` set.
- **Follow-up:** add the bootstrap state to the runbook as a recovery item.

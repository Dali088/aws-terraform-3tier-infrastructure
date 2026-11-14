# ADR-004: RDS PostgreSQL instead of DynamoDB

- **Status:** Accepted
- **Date:** 2026-11-03
- **Deciders:** Dali

## Context

The app needs a relational database for structured data with relationships, transactions, and ad-hoc queries. The project must also demonstrate private networking, encryption, and secret management.

## Options considered

| Option | Pros | Cons |
|---|---|---|
| RDS PostgreSQL (chosen) | Relational SQL, familiar, runs in private subnets, managed backups and patching | Hourly cost, instance management, must size and scale |
| DynamoDB | Serverless, pay per request, no VPC placement needed | Key-value model, query patterns must be designed up front, a different skill set |
| Aurora Serverless | Scales to zero | Cost behaviour is harder to predict, and the Free plan may limit it |
| Self-managed PostgreSQL on EC2 | Full control | Patching, backups and failover are all on us |

## Decision

Use RDS PostgreSQL 16 on `db.t3.micro` in private subnets. Connect through a DB subnet group, and allow only the app security group on port 5432.

## Consequences

- **Positive:** SQL and transactions fit a typical web app, and the private placement is simple to demonstrate.
- **Positive:** AWS handles backups (7 days retained), minor upgrades and encryption.
- **Negative:** the instance bills hourly, so it's destroyed after each session.
- **Negative:** DynamoDB would scale more easily for high-throughput key-value workloads. That isn't this app's shape.
- **Follow-up:** revisit if the access pattern becomes key-value at high volume.

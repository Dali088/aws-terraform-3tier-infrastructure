# ADR-005: Single-AZ database for dev, Multi-AZ for production

- **Status:** Accepted
- **Date:** 2026-11-03
- **Deciders:** Dali

## Context

Multi-AZ keeps a synchronous standby copy in a second availability zone and fails over automatically. It roughly doubles the instance cost. The dev environment is destroyed daily and holds no real users' data.

## Options considered

| Option | Availability | Cost | Notes |
|---|---|---|---|
| Single-AZ (chosen for dev) | Fails if the AZ fails. Restore from backup. | Base price | Fine for a learning environment |
| Multi-AZ | Automatic failover in about 1 to 2 minutes | About double | Required for production |
| Read replica | Manual promotion | Extra instance | Helps reads, not failover |

## Decision

`multi_az` is a variable defaulting to `false` in dev. Production sets it to `true`. The subnet group still spans two AZs, so enabling Multi-AZ later needs no network change.

## Consequences

- **Positive:** dev cost stays low, and the code path to Multi-AZ already exists.
- **Negative:** a single-AZ outage stops the database until it's restored, which is acceptable here.
- **Follow-up:** set `multi_az = true` in a production environment, and record the RTO and RPO targets.

# Contributing

This is a solo project, but it follows a real team workflow.

## Workflow

1. Never commit directly to `main`. It is protected.
2. Create a short-lived branch from an up-to-date `main`:

```bash
   git switch main && git pull
   git switch -c feature/short-description
```

3. Make small, focused commits.
4. Push the branch and open a pull request.
5. Merge with **squash and merge** once checks pass, then delete the branch.

## Branch names

| Prefix | Use for |
|---|---|
| `feature/` | New infrastructure or functionality |
| `fix/` | Bug fixes |
| `docs/` | Documentation only |
| `chore/` | Tooling and maintenance |

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/): `type(scope): short description`

- Types: `feat`, `fix`, `docs`, `chore`, `refactor`
- Imperative mood, lowercase, no trailing period, about 70 characters or fewer
- Example: `feat(vpc): add private subnets across two availability zones`

## Local setup

Install pre-commit and enable the hooks once per clone:

```bash
pipx install pre-commit
pre-commit install
```

Hooks run on every commit: terraform fmt and validate, tflint, checkov, and gitleaks. If a hook modifies files, stage them again and recommit. Do not bypass hooks with `--no-verify`.

## Terraform conventions

- Every variable and output has a `description`.
- Every resource is tagged with `Project`, `Environment` and `ManagedBy`.
- Comments explain **why**, not just what.
- Never commit state files, `.tfvars` files, or credentials.

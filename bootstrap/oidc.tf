# Tell AWS to trust tokens issued by GitHub Actions. This is a one-time setup
# per account, and it costs nothing.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # GitHub's published certificate thumbprints. Verify them against GitHub's
  # OIDC documentation if GitHub rotates its certificates.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

# ---------------------------------------------------------------------------
# Trust policies. Each role can be assumed only by one kind of GitHub run.
# The "sub" claim names the source: a pull request, or a push to main.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "trust_plan" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:pull_request"]
    }
  }
}

data "aws_iam_policy_document" "trust_apply" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only pushes to main may apply. A pull request can never change infrastructure.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

# ---------------------------------------------------------------------------
# Plan role: read everything, change nothing. It needs to write the state lock.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "github_plan" {
  name               = "github-actions-plan"
  assume_role_policy = data.aws_iam_policy_document.trust_plan.json
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.github_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_state_lock" {
  statement {
    sid       = "StateLockOnly"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/dev/terraform.tfstate.tflock"]
  }
}

resource "aws_iam_role_policy" "plan_state_lock" {
  name   = "state-lock"
  role   = aws_iam_role.github_plan.id
  policy = data.aws_iam_policy_document.plan_state_lock.json
}

# ---------------------------------------------------------------------------
# Apply role: changes infrastructure, but only from main.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "github_apply" {
  name               = "github-actions-apply"
  assume_role_policy = data.aws_iam_policy_document.trust_apply.json
}

# Broad on purpose for a learning account: Terraform creates many service types.
# Recorded as a known gap; narrow it to the services this project uses.
resource "aws_iam_role_policy_attachment" "apply_admin" {
  #checkov:skip=CKV_AWS_274:Learning account. Terraform creates many service types, so the apply role is broad by design for now. Narrow to the services this project uses before any production use.
  role       = aws_iam_role.github_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

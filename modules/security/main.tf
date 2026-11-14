# ---------------------------------------------------------------------------
# Security groups: two layers of firewall.
# The ALB group accepts public HTTP. The app group accepts traffic only from
# the ALB group, so a request must pass through the load balancer to reach
# the application.
# ---------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5:Attached to the ALB in Part 3e; this module is built before its consumers

  name        = "${var.name}-alb-sg"
  description = "Public HTTP entry point for the application load balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260:The load balancer must accept public HTTP. HTTPS with an ACM certificate is a planned stretch upgrade.
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward requests to application instances on the app port only"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "app" {
  #checkov:skip=CKV2_AWS_5:Attached to the Auto Scaling Group instances in Part 3e; this module is built before its consumers

  name        = "${var.name}-app-sg"
  description = "Application instances, reachable only from the load balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-app-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Application port, reachable only from the load balancer"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS outbound to ECR and AWS APIs, through the NAT gateway"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# ---------------------------------------------------------------------------
# IAM role for the instances. EC2 can assume it, and it grants only what the
# app needs: pulling one image repository and Session Manager access.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.name}-app-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "app_permissions" {
  # AWS requires this action to use "*". It returns a login token, not image
  # data, and the image permissions below are what is actually scoped.
  statement {
    sid       = "EcrLoginToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Pull-only actions, limited to this one repository. No push, no delete.
  statement {
    sid = "EcrPullOneRepository"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [var.ecr_repository_arn]
  }
  # Read the one database secret, nothing else in Secrets Manager.
  statement {
    sid       = "ReadDbSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }
}

resource "aws_iam_role_policy" "app" {
  name   = "${var.name}-app-ecr-pull"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_permissions.json
}

# AWS-managed policy that lets Session Manager open a shell without SSH
# keys or an open port 22.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# The instance profile is the container that attaches a role to an EC2
# instance. Launch templates in Part 3e reference this profile.
resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-app-profile"
  role = aws_iam_role.app.name

  tags = var.tags
}

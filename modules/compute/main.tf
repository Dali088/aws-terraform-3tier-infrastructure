# ---------------------------------------------------------------------------
# Application load balancer: the public entry point.
# ---------------------------------------------------------------------------

resource "aws_lb" "app" {
  #checkov:skip=CKV2_AWS_20:Learning environment serves HTTP only. HTTPS redirect needs an ACM certificate, a planned stretch upgrade.
  #checkov:skip=CKV2_AWS_28:WAF bills per request and is out of scope for this project. Revisit for production.
  #checkov:skip=CKV_AWS_150:Deletion protection is off so terraform destroy works every session. Enable it for production.
  #checkov:skip=CKV_AWS_91:Access logs need an S3 bucket, which is added in the hardening work.
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  # Drop malformed HTTP headers before they reach the app.
  drop_invalid_header_fields = true

  tags = merge(var.tags, {
    Name = "${var.name}-alb"
  })
}

# Target group: the set of instances the ALB sends traffic to.
resource "aws_lb_target_group" "app" {
  #checkov:skip=CKV_AWS_378:ALB-to-instance traffic stays inside the private VPC. TLS to instances is a hardening item.
  name        = "${var.name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  # The ALB asks /health every 30 seconds. Two passes mark an instance healthy,
  # three failures mark it unhealthy and stop traffic to it.
  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
  }

  tags = var.tags
}

# Listener: accepts port 80 and forwards to the target group.
resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_103:TLS policies apply only to HTTPS listeners. This listener is HTTP by design until the ACM stretch upgrade.
  #checkov:skip=CKV_AWS_2:HTTP only for now. HTTPS with an ACM certificate is a planned stretch upgrade.
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ---------------------------------------------------------------------------
# Launch template: the blueprint for each instance.
# ---------------------------------------------------------------------------

# Look up the latest Amazon Linux 2023 image ID instead of hardcoding one.
# AMI IDs differ by region and change with every update.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.name}-app-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  vpc_security_group_ids = [var.app_security_group_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  # Require IMDSv2 (session-token based metadata). It blocks a common SSRF
  # technique that steals instance role credentials.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Encrypted root volume, deleted with the instance.
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # The script runs at boot. base64encode is required by the launch template API.
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    region        = var.aws_region
    registry      = var.ecr_registry
    image         = var.image_uri
    app_port      = var.app_port
    db_host       = var.db_host
    db_name       = var.db_name
    db_secret_arn = var.db_secret_arn
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name}-app"
    })
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Auto Scaling Group: keeps the desired number of healthy instances running
# across both private subnets.
# ---------------------------------------------------------------------------

resource "aws_autoscaling_group" "app" {
  name                = "${var.name}-app-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  # Use the ALB's health check, not just "is the VM running". An instance whose
  # container crashed gets replaced, not just left running.
  health_check_type         = "ELB"
  health_check_grace_period = 180

  target_group_arns = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # ASG tags need one tag block per key, unlike the map used elsewhere.
  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

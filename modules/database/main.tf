# ---------------------------------------------------------------------------
# Network placement: RDS may only use the private subnets.
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-db-subnets"
  })
}

# Only the app instances may reach the database, and only on the PostgreSQL port.
resource "aws_security_group" "db" {
  #checkov:skip=CKV2_AWS_5:Attached to the RDS instance below; the scanner cannot follow the reference across resources
  name        = "${var.name}-db-sg"
  description = "PostgreSQL, reachable only from the application instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-db-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from the application instances only"
  referenced_security_group_id = var.app_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

# ---------------------------------------------------------------------------
# The database itself.
# ---------------------------------------------------------------------------

resource "aws_db_instance" "this" {
  #checkov:skip=CKV_AWS_157:Multi-AZ is off for dev to control cost; decided in ADR-005. Enable for production.
  #checkov:skip=CKV_AWS_293:Deletion protection is off so terraform destroy works every session. Enable for production.
  #checkov:skip=CKV_AWS_129:Engine log export to CloudWatch is deferred to the Day 6 observability work.
  #checkov:skip=CKV_AWS_353:Performance Insights adds cost and is part of the Day 6 observability work.
  #checkov:skip=CKV_AWS_118:Enhanced monitoring needs an IAM role and per-second metrics. Deferred to Day 6 observability.
  #checkov:skip=CKV2_AWS_30:Query logging needs a custom parameter group and adds log volume. Deferred to Day 6 observability.
  identifier = "${var.name}-db"
  engine     = "postgres"
  # Pinned major version. Upgrades are a deliberate change, not automatic.
  engine_version = "16"
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username

  # AWS generates the password and stores it in Secrets Manager. It never
  # appears in Terraform code, the state file's plain text, or Git.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  # Keep 7 days of automated backups so a mistake can be undone.
  backup_retention_period = 7

  # Skip the final snapshot so destroy is quick and free. Turn this off for production.
  skip_final_snapshot = true

  auto_minor_version_upgrade = true

  # Allow IAM-based login in addition to the password. Avoids long-lived
  # database passwords for future tooling.
  iam_database_authentication_enabled = true

  # Copy the Project, Environment and ManagedBy tags onto snapshots so backups
  # stay traceable to the cost and ownership tags.
  copy_tags_to_snapshot = true

  tags = merge(var.tags, {
    Name = "${var.name}-db"
  })
}

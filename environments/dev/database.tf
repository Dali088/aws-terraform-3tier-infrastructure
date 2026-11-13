module "database" {
  source = "../../modules/database"

  name                  = "${var.project_name}-${var.environment}"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  app_security_group_id = module.security.app_security_group_id

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

output "db_endpoint" {
  description = "Hostname the application connects to."
  value       = module.database.endpoint
}

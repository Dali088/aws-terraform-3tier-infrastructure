module "security" {
  source = "../../modules/security"

  name               = "${var.project_name}-${var.environment}"
  vpc_id             = module.vpc.vpc_id
  ecr_repository_arn = module.ecr.repository_arn
  db_secret_arn      = module.database.master_user_secret_arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

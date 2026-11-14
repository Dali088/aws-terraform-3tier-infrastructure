module "compute" {
  source = "../../modules/compute"

  name                  = "${var.project_name}-${var.environment}"
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  app_security_group_id = module.security.app_security_group_id
  instance_profile_name = module.security.instance_profile_name

  aws_region   = var.aws_region
  ecr_registry = split("/", module.ecr.repository_url)[0]
  image_uri    = "${module.ecr.repository_url}:v0.1.0"

  db_host       = module.database.endpoint
  db_name       = module.database.db_name
  db_secret_arn = module.database.master_user_secret_arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

output "app_url" {
  description = "Open this in a browser once the instances are healthy."
  value       = "http://${module.compute.alb_dns_name}"
}

output "target_group_arn" {
  description = "ARN of the target group, used to check instance health from the CLI."
  value       = module.compute.target_group_arn
}

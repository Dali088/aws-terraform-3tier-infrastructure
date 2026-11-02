module "ecr" {
  source = "../../modules/ecr"

  name = "${var.project_name}-app"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

output "ecr_repository_url" {
  description = "URL to push the application image to."
  value       = module.ecr.repository_url
}

module "vpc" {
  source = "../../modules/vpc"

  name               = "${var.project_name}-${var.environment}"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  enable_nat_gateway = true

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

output "vpc_id" {
  description = "ID of the dev VPC."
  value       = module.vpc.vpc_id
}

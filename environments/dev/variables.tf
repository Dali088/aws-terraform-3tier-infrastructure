variable "aws_region" {
  description = "AWS region where all resources are created."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name, used in resource names and the Project tag."
  type        = string
  default     = "aws-terraform-3tier"
}

variable "environment" {
  description = "Environment name (for example dev or prod), used in the Environment tag."
  type        = string
  default     = "dev"
}
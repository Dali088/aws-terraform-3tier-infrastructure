variable "aws_region" {
  description = "AWS region where the state bucket is created."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name, used in the bucket name and the Project tag."
  type        = string
  default     = "aws-terraform-3tier"
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the CI roles, in owner/name form."
  type        = string
  default     = "Dali088/aws-terraform-3tier-infrastructure"
}

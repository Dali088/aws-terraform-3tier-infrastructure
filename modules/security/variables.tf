variable "name" {
  description = "Name prefix for security groups and IAM resources, for example aws-terraform-3tier-dev."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the security groups belong to."
  type        = string
}

variable "app_port" {
  description = "Port the application listens on. The load balancer may forward traffic to this port only."
  type        = number
  default     = 8080
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository the instances may pull images from."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource in this module, on top of the default tags."
  type        = map(string)
  default     = {}
}

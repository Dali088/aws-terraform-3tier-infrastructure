variable "name" {
  description = "Name prefix for compute resources, for example aws-terraform-3tier-dev."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC, needed for the target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the load balancer, one per availability zone."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the instances, one per availability zone."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group attached to the load balancer."
  type        = string
}

variable "app_security_group_id" {
  description = "Security group attached to the application instances."
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile that gives instances ECR pull and Session Manager access."
  type        = string
}

variable "aws_region" {
  description = "Region used by the instance bootstrap script to log in to ECR."
  type        = string
}

variable "ecr_registry" {
  description = "ECR registry host, for example 123456789012.dkr.ecr.eu-west-1.amazonaws.com."
  type        = string
}

variable "image_uri" {
  description = "Full image reference to run, including the tag, for example registry/repo:v0.1.0."
  type        = string
}

variable "app_port" {
  description = "Port the application listens on inside the container and on the host."
  type        = number
  default     = 8080
}

variable "instance_type" {
  description = "EC2 instance type for the application. t3.micro keeps cost low."
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances at launch."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags applied to every resource, propagated to instances."
  type        = map(string)
  default     = {}
}

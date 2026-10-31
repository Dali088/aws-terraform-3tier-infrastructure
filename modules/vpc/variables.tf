variable "name" {
  description = "Name prefix for all VPC resources, for example aws-terraform-3tier-dev."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the whole VPC. /16 gives about 65,000 addresses to split into subnets."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Exactly two Availability Zones to spread subnets across, for resilience."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Provide exactly two availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per availability zone, in the same order as availability_zones."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per availability zone, in the same order as availability_zones."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway so private subnets can reach the internet outbound. It costs money while running."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags to add to every resource, on top of the default tags set by the caller."
  type        = map(string)
  default     = {}
}

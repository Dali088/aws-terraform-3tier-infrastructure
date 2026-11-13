variable "name" {
  description = "Name prefix for database resources, for example aws-terraform-3tier-dev."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC, needed for the database security group."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the database subnet group. RDS requires at least two AZs."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group of the application instances. Only this group may connect to the database."
  type        = string
}

variable "db_name" {
  description = "Name of the initial database created inside the instance."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username. The password is generated and stored by AWS Secrets Manager, never in code."
  type        = string
  default     = "appadmin"
}

variable "instance_class" {
  description = "RDS instance size. db.t3.micro is the cheapest size suitable for learning."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage size in GB. 20 GB is the smallest practical size for PostgreSQL."
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Whether to keep a standby copy in a second AZ. Off for dev to control cost; see ADR-005."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource, on top of the default tags."
  type        = map(string)
  default     = {}
}

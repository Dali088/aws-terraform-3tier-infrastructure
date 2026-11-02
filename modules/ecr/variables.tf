variable "name" {
  description = "Name of the ECR repository, for example aws-terraform-3tier-app."
  type        = string
}

variable "tags" {
  description = "Tags applied to the repository, on top of the default tags."
  type        = map(string)
  default     = {}
}

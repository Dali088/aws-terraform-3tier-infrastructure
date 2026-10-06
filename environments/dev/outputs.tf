output "account_id" {
  description = "AWS account ID Terraform is currently authenticated against."
  value       = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  description = "ARN of the IAM identity running Terraform."
  value       = data.aws_caller_identity.current.arn
}
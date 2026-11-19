output "state_bucket_name" {
  description = "Name of the S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_region" {
  description = "Region of the state bucket, needed in backend configurations."
  value       = var.aws_region
}

output "github_plan_role_arn" {
  description = "Role ARN that pull request workflows assume for terraform plan."
  value       = aws_iam_role.github_plan.arn
}

output "github_apply_role_arn" {
  description = "Role ARN that main-branch workflows assume for terraform apply."
  value       = aws_iam_role.github_apply.arn
}

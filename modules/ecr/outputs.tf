output "repository_url" {
  description = "Repository URL used in docker push and image references."
  value       = aws_ecr_repository.this.repository_url
}


output "repository_arn" {
  description = "ARN of the ECR repository, used to limit IAM pull permissions to this one repository."
  value       = aws_ecr_repository.this.arn
}

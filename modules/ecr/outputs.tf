output "repository_url" {
  description = "Repository URL used in docker push and image references."
  value       = aws_ecr_repository.this.repository_url
}

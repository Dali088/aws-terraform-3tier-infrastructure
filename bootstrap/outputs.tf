output "state_bucket_name" {
  description = "Name of the S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_region" {
  description = "Region of the state bucket, needed in backend configurations."
  value       = var.aws_region
}

# The ECR repository stores container images for the application.
resource "aws_ecr_repository" "this" {
  #checkov:skip=CKV_AWS_136:AES256 encryption is enabled; a customer KMS key costs about $1/month and adds key management for a learning project. Revisit for production.

  name = var.name

  # Immutable tags stop someone from silently replacing "v1" with a different image.
  # Every release gets a new tag, so what was tested is what gets deployed.
  image_tag_mutability = "IMMUTABLE"

  # Scan every pushed image for known vulnerabilities (uses AWS's free basic scanning).
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encrypt images at rest with AWS-managed keys.
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name = var.name
  })
  force_delete = true
}

# Keep only the 10 most recent images so storage cost stays near zero.
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

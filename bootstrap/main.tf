provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "shared"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  # S3 bucket names are global across ALL AWS accounts, so we add the
  # account ID to make the name unique and predictable.
  bucket_name = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
}

# checkov:skip comments below are deliberate and explained: each one is a
# best practice that costs money or adds complexity without real benefit
# for a single-person learning project.
resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV_AWS_18:Access logging needs a second bucket; not worth it for a learning project
  #checkov:skip=CKV_AWS_144:Cross-region replication is unnecessary here and costs money
  #checkov:skip=CKV_AWS_145:SSE-S3 encryption is enough; a KMS key adds cost and complexity
  #checkov:skip=CKV2_AWS_62:No event notifications are needed

  bucket = local.bucket_name

  # Safety net: if someone runs `terraform destroy` here, Terraform refuses.
  # Losing this bucket means losing the record of everything we built.
  lifecycle {
    prevent_destroy = true
  }
}

# Versioning keeps every previous copy of the state file, so a corrupted or
# overwritten state can be rolled back.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# State can contain sensitive values, so it is encrypted at rest.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Hard block on any form of public access, regardless of other settings.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Old state versions are useful for a while but would pile up forever.
# Delete versions older than 30 days, and clean up half-finished uploads.
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Refuse any request that isn't encrypted in transit (plain HTTP).
data "aws_iam_policy_document" "state_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_tls_only.json

  # Applying a bucket policy while the public access block is still being
  # created can fail with a conflict, so we wait for it explicitly.
  depends_on = [aws_s3_bucket_public_access_block.state]
}

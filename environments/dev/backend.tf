terraform {
  backend "s3" {
    bucket = "aws-terraform-3tier-tfstate-331191957870"
    key    = "dev/terraform.tfstate"
    region = "eu-west-1"


    encrypt      = true
    use_lockfile = true
  }
}

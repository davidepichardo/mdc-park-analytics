terraform {
  backend "s3" {
    bucket         = "mdc-terraform-state-bucket" # Name of the S3 bucket for Terraform state
    key            = "terraform.tfstate" # Path within the bucket to store the state file
    region         = "us-west-2" # AWS region where the S3 bucket is located
    dynamodb_table = "mdc-state-locking-table" # DynamoDB table for state locking
    encrypt = true # Enable encryption for the state file

  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 bucket to store raw data for the park facility dataset. 
resource "aws_s3_bucket" "data_lake_bucket" {
  bucket        = var.bucket_name
  force_destroy = false
}

resource "aws_s3_bucket" "state_bucket" {
    bucket        = var.state_bucket_name # Name of the S3 bucket for Terraform state
    force_destroy = false
}

#Bucket versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.data_lake_bucket.id # Reference the S3 bucket created above

  versioning_configuration {
    status = "Enabled" # Enable versioning
  }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# "Uniform bucket level access" ~ control prin policy/ACL; recomandat: block public access
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.data_lake_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Dedicated public access block for the State Bucket
resource "aws_s3_bucket_public_access_block" "state_block_public" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle: delete objects older than 30 days (echivalent lifecycle_rule age=30)
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_rules" {
  bucket = aws_s3_bucket.data_lake_bucket.id

  rule {
    id     = "Retain data for 365 days"
    status = "Enabled"

    expiration {
      days = 365
    }
    filter {
      prefix = "" # Apply to all objects in the bucket
    }
  }
}

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "mdc-state-locking-table" # You can name this anything
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S" # String type is required for the LockID
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "Management"
  }
}
resource "aws_s3_bucket" "plunder_bucket" {
  bucket = "plunder-cove-assets-bucket"

  tags = {
    Name        = "PlunderCoveAssets"
    Environment = "Production"
    Project     = "PlunderCove"
  }
}

resource "aws_s3_bucket_versioning" "plunder_bucket_versioning" {
  bucket = aws_s3_bucket.plunder_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "plunder_bucket_block" {
  bucket = aws_s3_bucket.plunder_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

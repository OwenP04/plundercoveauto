resource "aws_s3_bucket" "plunder_assets" {
  bucket = "plunder-cove-assets-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "plunder_assets" {
  bucket = aws_s3_bucket.plunder_assets.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "plunder_assets" {
  bucket = aws_s3_bucket.plunder_assets.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.plunder_assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.plunder_assets.arn}/*"
      }
    ]
  })
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "web" {
  bucket        = "plunder-cove-assets-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "PlunderCoveWeb"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_website_configuration" "web" {
  bucket = aws_s3_bucket.web.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# 🔓 Step 1: Disable Block Public Access
resource "aws_s3_bucket_public_access_block" "web" {
  bucket = aws_s3_bucket.web.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 🧠 Step 2: Delay policy creation until block is disabled
resource "aws_s3_bucket_policy" "web" {
  depends_on = [aws_s3_bucket_public_access_block.web]
  bucket     = aws_s3_bucket.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = "*"
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.web.arn}/*"
    }]
  })
}

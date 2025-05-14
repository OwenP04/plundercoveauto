resource "aws_iam_role" "plunder_read" {
  name               = "plunder-read"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "PlunderReadRole"
  }
}

resource "aws_iam_role_policy" "plunder_read_policy" {
  name   = "PlunderReadDynamoDB"
  role   = aws_iam_role.plunder_read.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:Query", "dynamodb:Scan"]
        Resource = aws_dynamodb_table.plunder_guest_data.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "plunder_read_profile" {
  name = "PlunderReadInstanceProfile"
  role = aws_iam_role.plunder_read.name
}
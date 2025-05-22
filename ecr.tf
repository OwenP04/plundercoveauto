# --- ECR Repository for Web App ---
resource "aws_ecr_repository" "plunder_web_app" {
  name                 = "plunder-cove-web-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "PlunderCoveWebApp"
    Environment = "Production"
    Project     = "PlunderCove"
  }
}

# --- IAM Policy for EC2 to Access ECR ---
resource "aws_iam_role_policy" "ec2_ecr_access" {
  name   = "PlunderCoveEC2ECRAccess"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

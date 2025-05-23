provider "aws" {
  region = "us-east-1"
}

# --- VPC ---
resource "aws_vpc" "plunder_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "PlunderCoveVPC"
  }
}

resource "aws_subnet" "plunder_subnet" {
  vpc_id                  = aws_vpc.plunder_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "PlunderCoveSubnet"
  }
}

# Additional Subnet for ALB (Multi-AZ)
resource "aws_subnet" "plunder_subnet_b" {
  vpc_id                  = aws_vpc.plunder_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "PlunderCoveSubnetB"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "plunder_igw" {
  vpc_id = aws_vpc.plunder_vpc.id

  tags = {
    Name = "PlunderCoveIGW"
  }
}

# --- Route Table ---
resource "aws_route_table" "plunder_rt" {
  vpc_id = aws_vpc.plunder_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.plunder_igw.id
  }

  tags = {
    Name = "PlunderCoveRouteTable"
  }
}

resource "aws_route_table_association" "plunder_rta_a" {
  subnet_id      = aws_subnet.plunder_subnet.id
  route_table_id = aws_route_table.plunder_rt.id
}

resource "aws_route_table_association" "plunder_rta_b" {
  subnet_id      = aws_subnet.plunder_subnet_b.id
  route_table_id = aws_route_table.plunder_rt.id
}

# --- IAM Role for Lambda ---
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "LambdaExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# --- Lambda Function ---
resource "aws_lambda_function" "route_optimizer" {
  function_name    = "PlunderCoveRouteOptimizer"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

# --- EC2 IAM Role + Instance Profile ---
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "PlunderCoveEC2Role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "PlunderCoveEC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}

# --- EC2 Key Pair ---
resource "tls_private_key" "plunder_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "plunder_key" {
  key_name   = "PlunderCoveKey"
  public_key = tls_private_key.plunder_key.public_key_openssh
}

# Save Private Key Locally
resource "local_file" "plunder_key_file" {
  content  = tls_private_key.plunder_key.private_key_pem
  filename = "PlunderCoveKey.pem"
}

# --- EC2 Instance ---
data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "plunder_ec2" {
  ami                    = data.aws_ami.amzn2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.plunder_key.key_name
  vpc_security_group_ids = [aws_security_group.plunder_sg.id]
  subnet_id              = aws_subnet.plunder_subnet.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Welcome to Plunder Cove!</h1>" > /var/www/html/index.html
              # Add commands to deploy your app (e.g., clone repo, install dependencies)
              EOF

  tags = {
    Name = "PlunderCoveEC2"
  }
}

# --- Application Load Balancer ---
resource "aws_lb_target_group_attachment" "plunder_tg_attachment" {
  target_group_arn = aws_lb_target_group.plunder_tg.arn
  target_id        = aws_instance.plunder_ec2.id
  port             = 80
}

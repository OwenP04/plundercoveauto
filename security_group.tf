resource "aws_security_group" "plunder_sg" {
  name        = "PlunderCoveSG"
  description = "Security group for Plunder Cove EC2 and ALB"
  vpc_id      = aws_vpc.plunder_vpc.id

  ingress {
    description = "SSH from approved IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP for public routing"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "PlunderCoveSG"
  }
}
resource "aws_security_group" "eb_sg" {
  name        = "plunder-eb-sg"
  description = "Security group for Plunder Cove ECS and ALB"
  vpc_id      = aws_vpc.plunder_vpc.id # Ensure plunder_vpc is defined in main.tf

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project     = "PlunderCove"
    Environment = "Production"
  }
}

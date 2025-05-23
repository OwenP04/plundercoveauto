# --- ECS Cluster ---
resource "aws_ecs_cluster" "plunder_cluster" {
  name = "plunder-cove-cluster"
  tags = {
    Project     = "PlunderCove"
    Environment = "Production"
  }
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "plunder_task" {
  family                   = "plunder-cove-web-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ec2_role.arn

  container_definitions = jsonencode([
    {
      name      = "plunder-web-app"
      image     = "${aws_ecr_repository.plunder_web_app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/plunder-cove-web"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "plunder"
        }
      }
    }
  ])

  tags = {
    Project     = "PlunderCove"
    Environment = "Production"
  }
}

# --- ECS Service ---
resource "aws_ecs_service" "plunder_service" {
  name            = "plunder-cove-web-service"
  cluster         = aws_ecs_cluster.plunder_cluster.id
  task_definition = aws_ecs_task_definition.plunder_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.plunder_subnet_1.id, aws_subnet.plunder_subnet_2.id]
    security_groups  = [aws_security_group.eb_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.plunder_tg.arn
    container_name   = "plunder-web-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.plunder_listener]

  tags = {
    Project     = "PlunderCove"
    Environment = "Production"
  }
}

# --- Application Load Balancer ---
resource "aws_lb" "plunder_alb" {
  name               = "plunder-cove-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.eb_sg.id]
  subnets           = [aws_subnet.plunder_subnet_1.id, aws_subnet.plunder_subnet_2.id]

  tags = {
    Project     = "PlunderCove"
    Environment = "Production"
  }
}

# --- ALB Target Group ---
resource "aws_lb_target_group" "plunder_tg" {
  name        = "plunder-cove-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.plunder_vpc.id
  target_type = "ip"

  health_check {
    path                = "/treasure-hunt.html"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Project     = "PlunderCove"
    Environment = "Production"
  }
}

# --- ALB Listener ---
resource "aws_lb_listener" "plunder_listener" {
  load_balancer_arn = aws_lb.plunder_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.plunder_tg.arn
  }
}

# --- ECS Execution Role ---
resource "aws_iam_role" "ecs_execution_role" {
  name = "PlunderCoveECSExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "PlunderCove"
  }
}

resource "aws_iam_role_policy" "ecs_execution_policy" {
  name   = "PlunderCoveECSExecutionPolicy"
  role   = aws_iam_role.ecs_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "plunder_log_group" {
  name              = "/ecs/plunder-cove-web"
  retention_in_days = 7

  tags = {
    Project     = "PlunderCove"
    Environment = "Production"
  }
}

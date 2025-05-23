# --- Elastic Beanstalk Application ---
resource "aws_elastic_beanstalk_application" "plunder_app" {
  name        = "plunder-cove-eb-app"
  description = "Elastic Beanstalk app for Plunder Cove Docker web app"
}

# --- EB Environment Configuration Template ---
resource "aws_elastic_beanstalk_environment" "plunder_env" {
  name                = "plunder-cove-eb-env"
  application         = aws_elastic_beanstalk_application.plunder_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.9 running Docker"

  setting {
    namespace = "aws:elasticbeanstalk:container:docker"
    name      = "Image"
    value     = "${aws_ecr_repository.plunder_web_app.repository_url}:latest"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENVIRONMENT"
    value     = "Production"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2_instance_profile.name
  }

  tags = {
    Project     = "PlunderCove"
    Environment = "Production"
  }
}

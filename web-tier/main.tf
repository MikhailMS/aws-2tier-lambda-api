####
## Terraform providers
###
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = var.bucket
    key    = var.key
    region = var.region
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "eu-west-2"
  profile = "default"
}
####


####
## Configure Web Tier infrastructure
###
# Create Elastic Load Balancer
resource "aws_security_group" "webtier_allow_in_tls" {
  name        = "WebTier Allow TLS"
  description = "Web server security group"
  vpc_id      = local.network_output.aws_vpc_network.id

  ingress {
    # This one required to allow traffic from LB listener to Target Group
    description      = "Inbound TLS traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    # This one required to allow secure traffic from Internet
    description      = "Inbound TLS traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    # This one required to allow SSH traffic from Internet
    description      = "Inbound TLS traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  

  egress {
    # This one required to allow secure traffic into Internet
    description      = "Outbound TLS traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    # This one required to allow traffic from WebTier LB health checks
    description      = "Outbound TLS traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [local.network_output.aws_vpc_network.cidr_block]
  }


  tags = {
    Name = "webtier_allow_tls"
  }
}

resource "aws_lb" "webtier_lb" {
  name    = "WebTier-LB"
  subnets = [for subnet_id in local.network_output.aws_public_subnets: subnet_id]

  security_groups = [aws_security_group.webtier_allow_in_tls.id]

  depends_on = [aws_security_group.webtier_allow_in_tls]
}

resource "aws_lb_target_group" "webtier_lb_target_group" {
  vpc_id   = local.network_output.aws_vpc_network.id
  name     = "WebTier-LB-Target-Group"
  port     = 80
  protocol = "HTTP"

  deregistration_delay = 20

  health_check {
    interval            = 35
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 30
  }
}

resource "aws_lb_listener" "webtier_lb_listener" {
  load_balancer_arn = aws_lb.webtier_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.tls_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webtier_lb_target_group.arn
  }

  depends_on = [aws_lb.webtier_lb, aws_lb_target_group.webtier_lb_target_group]
}


# Create IAM role and add IAM policy to it, so EC2 instance can access AWS ECR
resource "aws_iam_role" "webserver_role" {
  name = "webserver_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      created-by = "Terraform"
  }
}

resource "aws_iam_role_policy" "ecr_policy" {
  name = "webserver_ecr_policy"
  role = aws_iam_role.webserver_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "ecr:GetAuthorizationToken",
                "ecr:ListImages"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "webserver_profile" {
  name = "webserver_profile"
  role = aws_iam_role.webserver_role.name
}


# Fetch ECR data, so we know what to pass to Launch template
data "aws_ecr_repository" "webserver_ecr_info" {
  name = var.ecr_settings.repository
}


# Create Autoscaling Groups
resource "aws_launch_template" "webserver_instance" {
  name_prefix   = var.launch_template_settings.name_prefix
  image_id      = var.launch_template_settings.image_id
  instance_type = var.launch_template_settings.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.webserver_profile.name
  }
  
  key_name      = var.launch_template_settings.key_name

  vpc_security_group_ids = [aws_security_group.webtier_allow_in_tls.id]

  user_data = base64encode(templatefile("webtier_launch_template.sh", { webtier_dns_name = aws_lb.webtier_lb.dns_name, ecr_account_id = var.ecr_settings.account_id, image_region = var.ecr_settings.region, image_repository = var.ecr_settings.repository, image_tag = data.aws_ecr_repository.webserver_ecr_info.most_recent_image_tags[0] }))
}

resource "aws_autoscaling_group" "webserver_asg" {
  name                      = "webserver-as-group"
  min_size                  = 2
  max_size                  = 4

  desired_capacity          = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"

  target_group_arns = [aws_lb_target_group.webtier_lb_target_group.arn]

  launch_template {
    id      = aws_launch_template.webserver_instance.id
    version = "$Latest"
  }

  vpc_zone_identifier = [for subnet_id in local.network_output.aws_public_subnets: subnet_id]
}
####

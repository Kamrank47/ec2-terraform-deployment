resource "aws_security_group" "elb_sg" {
  name        = "elb-security-group"
  description = "Security group for the ELB"
  vpc_id      = var.VPC_ID
  # Define ingress rules for your ELB security group
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from all IP addresses
  }

  # Allow HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic to all IP addresses
  }

  tags = var.tags
}

resource "aws_lb" "elastic_load_balancer" {
  name               = var.ELB_PUBLIC_NAME
  internal           = false         # Set to true for internal ELB
  load_balancer_type = "application" # Specify the load balancer type (e.g., application, network)

  security_groups = [
    aws_security_group.elb_sg.id # Reference the ID of the ELB security group
  ]

  subnets                    = var.VPC_SUBNET_ID
  enable_deletion_protection = false # Set to true to prevent accidental deletion
  tags                       = var.tags
}

resource "aws_lb_target_group" "lb_target_group" {
  name     = var.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.VPC_ID
  tags     = var.tags
  health_check {
    enabled             = true           # Enable health checks
    path                = "/api"         # The destination for the health check request
    protocol            = "HTTP"         # The protocol to use for the health check
    port                = "traffic-port" # The port to use for the health check
    interval            = 30             # The time between health checks in seconds
    timeout             = 20             # The amount of time to wait when receiving a response from the health check
    healthy_threshold   = 2              # The number of consecutive successful health checks required before considering an unhealthy target healthy
    unhealthy_threshold = 2              # The number of consecutive failed health checks required before considering a target unhealthy
  }
}

# ACM certificate
resource "aws_acm_certificate" "elb_cert" {
  domain_name       = var.elb_allowed_host
  validation_method = "DNS"

  # optional: include www as SAN if desired
  # subject_alternative_names = ["www.${var.elb_allowed_host}"]

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Certificate validation resource
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = aws_acm_certificate.elb_cert.arn
}

resource "aws_lb_listener" "backend_lb" {
  load_balancer_arn = aws_lb.elastic_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied"
      status_code  = "403"
    }
  }
}

# HTTPS listener using the ACM certificate
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.elastic_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.elb_cert.arn

  # Only create after certificate is validated
  depends_on = [aws_acm_certificate_validation.cert_validation]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

# API routes rule
resource "aws_lb_listener_rule" "api_routes" {
  listener_arn = aws_lb_listener.backend_lb.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }

  condition {
    host_header {
      values = [var.elb_allowed_host]
    }
  }

  condition {
    path_pattern {
      values = [
        "/api",
        "/api/*"
      ]
    }
  }
}

# Docs routes rule
resource "aws_lb_listener_rule" "docs_routes" {
  listener_arn = aws_lb_listener.backend_lb.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }

  condition {
    host_header {
      values = [var.elb_allowed_host]
    }
  }

  condition {
    path_pattern {
      values = [
        "/docs",
        "/docs/*",
        "/docs-json"
      ]
    }
  }
}


resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.project_name}-${var.environment}-redis-subnet"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "redis_security_group" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for Redis cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_elasticache_parameter_group" "redis_parameter_group" {
  family = var.parameter_group_family
  name   = "${var.project_name}-${var.environment}-redis-params"

  dynamic "parameter" {
    for_each = var.redis_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = var.tags
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-${var.environment}-redis"
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.redis_parameter_group.name
  port                 = var.port
  security_group_ids   = [aws_security_group.redis_security_group.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name

  tags = var.tags
} 
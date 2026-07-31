resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-security-group"
  description = "Security group attached with EC2"
  vpc_id      = var.VPC_ID

  # Default SSH ingress rule
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.SSH_ALLOWED_IP]
    description = "SSH access"
  }

  # ELB security group access
  dynamic "ingress" {
    for_each = var.elb_security_group_id != "" ? [1] : []
    content {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      security_groups = [var.elb_security_group_id]
      description     = "Access from ELB security group"
    }
  }

  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = var.security_group_rules.ingress_rules
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
      description     = ingress.value.description
    }
  }

  # Dynamic egress rules
  dynamic "egress" {
    for_each = var.security_group_rules.egress_rules
    content {
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_blocks     = lookup(egress.value, "cidr_blocks", null)
      security_groups = lookup(egress.value, "security_groups", null)
      description     = egress.value.description
    }
  }

  # Lifecycle block to ignore ingress changes when using separate aws_security_group_rule resources
  lifecycle {
    ignore_changes = [ingress]
  }

  tags = var.tags
}

# Create security group for EC2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "${var.instance_name}-sg"
  description = "Security group for ${var.instance_name} EC2 instance"
  vpc_id      = var.vpc_id




  dynamic "ingress" {
    for_each = [for rule in var.security_group_rules : rule if rule.type == "ingress"]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      # Only include cidr_blocks if source_security_group_id is not set
      cidr_blocks = ingress.value.source_security_group_id == null ? ingress.value.cidr_blocks : null

      # Only include source_security_group_id if it's provided
      security_groups = ingress.value.source_security_group_id != null ? [ingress.value.source_security_group_id] : null
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = [for rule in var.security_group_rules : rule if rule.type == "egress"]
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  # Lifecycle block to ignore ingress changes when using separate aws_security_group_rule resources
  lifecycle {
    ignore_changes = [ingress]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_name}-sg"
    }
  )
}

# Create IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Attach managed policies to the IAM role
resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  count      = length(var.managed_policy_arns)
  role       = aws_iam_role.ec2_role.name
  policy_arn = var.managed_policy_arns[count.index]
}

# Create instance profile for the IAM role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.role_name}-profile"
  role = aws_iam_role.ec2_role.name
}

# Create EC2 instance
resource "aws_instance" "ec2_instance" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  user_data              = var.user_data

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
  }

  tags = merge(
    var.tags,
    {
      Name = var.instance_name
    }
  )
}

# Create Elastic IP if enabled
resource "aws_eip" "ec2_eip" {
  count    = var.enable_elastic_ip ? 1 : 0
  instance = aws_instance.ec2_instance.id
  domain   = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_name}-eip"
    }
  )
}

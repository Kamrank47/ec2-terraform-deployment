resource "aws_autoscaling_group" "ec2_asg" {
  name = "Autoscaling_group"
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
  min_size            = var.ASG_MIN_SIZE
  max_size            = var.ASG_MAX_SIZE
  desired_capacity    = var.ASG_DESIRED_CAPACITY
  vpc_zone_identifier = var.VPC_SUBNET_ID
  target_group_arns   = var.target_group_arn != null ? [var.target_group_arn] : []

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Create the role for EC2 instance
resource "aws_iam_role" "EC2_Service_Role" {
  name = var.ec2_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com",
      },
    }],
  })
  tags = var.tags
}

# Attach different policies with EC2 role
resource "aws_iam_role_policy_attachment" "ec2_role_permissions" {
  count      = length(var.ec2_role_permissions)
  policy_arn = var.ec2_role_permissions[count.index]
  role       = aws_iam_role.EC2_Service_Role.name
}

resource "aws_iam_instance_profile" "EC2_instance_profile" {
  name = aws_iam_role.EC2_Service_Role.name
  role = aws_iam_role.EC2_Service_Role.id
  tags = var.tags
}

resource "aws_launch_template" "launch_template" {
  name          = "asg_launch_template"
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = var.ec2_key_pair_name
  iam_instance_profile {
    name = aws_iam_instance_profile.EC2_instance_profile.name
  }

  user_data = base64encode(file("${path.module}/../../Utils/EC2_user_data.sh"))

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      iops                  = 3000
      throughput            = 125
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.ec2_security_group_id]
    subnet_id                   = var.VPC_SUBNET_ID[0]
  }

  tags = var.tags
}

# CloudWatch Alarm for CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.ec2_role_name}-cpu-usage-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when CPU exceeds 70%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2_asg.name
  }
  alarm_actions = var.sns_topic_arns
}

# CloudWatch Alarm for Memory Utilization (from CloudWatch Agent)
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.ec2_role_name}-memory-usage-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when memory usage exceeds 70%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2_asg.name
  }
  alarm_actions = var.sns_topic_arns
}
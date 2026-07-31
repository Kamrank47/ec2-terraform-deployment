resource "aws_iam_role" "this" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = var.assume_role_principal }
    }]
  })
  tags = var.tags

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
    # Remove prevent_destroy to allow Terraform to manage the role lifecycle
    # prevent_destroy = true # <-- REMOVE THIS LINE
  }
}

resource "aws_iam_role_policy_attachment" "managed" {
  count      = length(var.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = var.managed_policy_arns[count.index]
}

resource "aws_iam_role_policy" "inline" {
  count = length(var.policy_statements) > 0 ? 1 : 0
  name  = "${var.role_name}-inline-policy"
  role  = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for s in var.policy_statements : merge(
        {
          Effect   = lookup(s, "effect", "Allow"),
          Action   = s.actions,
          Resource = s.resources
        },
        can(s.sid) && s.sid != null && s.sid != "" ? { Sid = s.sid } : {},
        length(lookup(s, "condition", [])) > 0 ? {
          Condition = {
            for c in s.condition : c.test => { "${c.variable}" = c.values }
          }
        } : {}
      )
      if length(s.actions) > 0 && length(s.resources) > 0
    ]
  })
}

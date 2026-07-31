resource "aws_budgets_budget" "this" {
  count = var.create_budget ? 1 : 0
  
  name       = var.budget_name
  budget_type = var.budget_type
  limit_amount = var.limit_amount
  limit_unit = var.limit_unit
  time_unit  = var.time_unit
  time_period_start = var.time_period_start
  time_period_end   = var.time_period_end

  cost_types {
    include_credit             = true
    include_discount           = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = true
    include_subscription       = true
    include_support            = true
    include_tax                = true
    include_upfront            = true
    use_amortized              = false
    use_blended                = false
  }

  notification {
    comparison_operator        = var.notification.comparison_operator
    threshold                  = var.notification.threshold
    threshold_type            = var.notification.threshold_type
    notification_type         = var.notification.notification_type
    subscriber_email_addresses = var.notification.subscriber_email_addresses
  }

  tags = var.tags
}

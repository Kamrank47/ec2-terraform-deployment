output "budget_id" {
  description = "The ID of the budget"
  value       = var.create_budget ? aws_budgets_budget.this[0].id : null
}

output "budget_arn" {
  description = "The ARN of the budget"
  value       = var.create_budget ? aws_budgets_budget.this[0].arn : null
}

output "budget_name" {
  description = "The name of the budget"
  value       = var.create_budget ? aws_budgets_budget.this[0].name : null
}

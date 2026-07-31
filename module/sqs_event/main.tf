resource "aws_lambda_event_source_mapping" "this" {
  function_name                      = var.function_name
  event_source_arn                   = var.event_source_arn
  enabled                            = var.enabled
  batch_size                         = var.batch_size
  maximum_batching_window_in_seconds = var.maximum_batching_window_in_seconds
  function_response_types            = var.function_response_types

  dynamic "filter_criteria" {
    for_each = var.filter_criteria != null ? [var.filter_criteria] : []
    content {
      dynamic "filter" {
        for_each = lookup(filter_criteria.value, "filters", [])
        content {
          pattern = filter.value.pattern
        }
      }
    }
  }
}
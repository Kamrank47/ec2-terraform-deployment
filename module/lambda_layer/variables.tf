variable "layer_name" {
  description = "Name for the Lambda layer"
  type        = string
}

variable "description" {
  description = "Description for the Lambda layer"
  type        = string
  default     = null
}

variable "compatible_runtimes" {
  description = "List of compatible runtimes (e.g., [\"nodejs18.x\"])"
  type        = list(string)
}

variable "compatible_architectures" {
  description = "List of compatible architectures (e.g., [\"x86_64\"])"
  type        = list(string)
  default     = ["x86_64"]
}

variable "license_info" {
  description = "License info for the layer"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the layer version"
  type        = map(string)
  default     = {}
}

variable "EC2_INSTANCE_PEM_FILE_NAME" {
  description = ".pem file name is required"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

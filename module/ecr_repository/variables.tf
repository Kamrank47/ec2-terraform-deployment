variable "ECR_REPOSITORY_NAME_FOR_BE" {
  type        = string
  description = "ECR Repository Name for storing the docker images"
}


variable "tags" {
  type    = map(string)
  default = {}
}
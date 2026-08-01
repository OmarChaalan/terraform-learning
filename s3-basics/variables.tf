variable "region" {
  description = "The region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment lists: production, staging, dev, testing"
  type        = string
  default     = "testing"
}
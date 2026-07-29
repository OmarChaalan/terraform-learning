locals {
  name_prefix = "${var.environment}-${var.region}"

  common_tags = {
    ManagedBy   = "terraform"
    Owner       = "omar"
    Environment = var.environment
    region      = var.region
  }
}
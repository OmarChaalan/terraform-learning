locals {
  name_prefix = "${var.region}-${var.environment}"

  common_tags = {
    ManagedBy   = "terraform"
    Owner       = "omar"
    Region      = var.region
    Environment = var.environment
  }

  is_production = var.environment == "production"
}
locals {
    name_prefix = "${var.environment}-${var.region}"

    common_tags = {
        Environment = var.environment
        ManagedBy = "terraform"
        Owner = "omar"
        Region = var.region
    }

    is_production = var.environment == "production"
}
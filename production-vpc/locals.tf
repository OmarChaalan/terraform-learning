locals {
    name_prefix = "${var.region}-${var.environment}"

    common_tags = {
        ManagedBy = "terraform"
        Region = var.region
        Environment = var.environment
        Owner = "omar"
    }

    is_production = var.environment == "production"
}
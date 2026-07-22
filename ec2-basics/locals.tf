locals {
    name_prefix = "${var.environment}-${var.region}"

    common_tags = {
        ManagedBy = "terraform"
        Environment = var.environment
        Region = var.region
        Owner = "omar"
    }
}
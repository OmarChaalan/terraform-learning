locals {
    name_prefix = "${var.environment}-${var.region}"

    common_tags = {
        Environment = var.environment
        ManagedBy = "terraform"
        Owner = "omar"
    }

    rendered_script = tempaltefile("${path.module}/example_script.sh.tpl", {
        environment = var.environment
    })

    encoded_script = base64dencode(local.rendered_script)
}
output "password_was_retrieved" {
    description = "Confirms the SSM parameter was successfully read (does not expose the value)"
    value = nonsensitive(length(data.aws_ssm_parameter.db_password.value) > 0)
}

output "db_password" {
    value = data.aws_ssm_parameter.db_password.value
    sensitive = true
}
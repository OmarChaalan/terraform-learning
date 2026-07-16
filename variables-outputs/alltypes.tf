# String — any text
variable "name" {
  type    = string
  default = "omar"
}

# Number — integer or float
variable "port" {
  type    = number
  default = 443
}

# Boolean — true or false only
variable "enabled" {
  type    = bool
  default = true
}

# List — ordered collection of same type
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# Map — key value pairs of same type
variable "tags" {
  type = map(string)
  default = {
    Owner       = "omar"
    Environment = "dev"
  }
}

# Object — structured data with named attributes of different types
variable "vpc_config" {
  type = object({
    cidr_block   = string
    enable_dns   = bool
    subnet_count = number
  })
  default = {
    cidr_block   = "10.0.0.0/16"
    enable_dns   = true
    subnet_count = 2
  }
}

variable "environment" {
    description = "Environment Name"
    type = string
    default = "dev"

    validation {
        condition = contains(["dev", "staging", "production"], var.environment)
        error_message = "Environment must be dev, staging, or production."
    }
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"

    validation {
        condition = can(cidrnetmask(var.vpc_cidr))
        error_message = "Must be a valid CIDR block like 10.0.0.0/16."
    }
}


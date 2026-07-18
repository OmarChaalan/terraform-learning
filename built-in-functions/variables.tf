variable "region" {
    description = "What region resources will be deployed in"
    type = string
    default = "us-east-1"
}

variable "environment" {
    description = "Which environment to deploy in: production, dev, testing"
    type = string
    default = "dev"
}

variable "storage_tier_map" {
    description = "Storage tier per environment, with fallback via lookup()"
    type = map(string)
    default = {
        dev = "standard"
        prod = "intelligent-tiering"
    }
}

variable "bucket_purposes" {
    description = "List of purposes to loop over with for_each + toset()"
    type = list(string)
    default = ["logs", "backups"] 
}
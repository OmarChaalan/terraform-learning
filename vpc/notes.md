# VPC Notes

## Key Concepts
- enable_dns_support — turns DNS engine ON inside VPC (always true)
- enable_dns_hostnames — gives EC2 instances a DNS hostname (always true)
- map_public_ip_on_launch — true on public subnets ONLY, never on private subnets
- Resource names use underscores not hyphens (aws_vpc.my_first_vpc not my-first-vpc)

## Commands
terraform init     # download providers, run once per project
terraform plan     # preview changes, always read before applying
terraform apply    # build the infrastructure
terraform destroy  # tear everything down, always run after practice

## My Mistakes
- Used hyphens in resource names instead of underscores
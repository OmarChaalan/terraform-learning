# Day 2 — Providers + State Management

## What is a Provider?
- A provider is a plugin that lets Terraform talk to a specific platform (AWS, Azure, GCP)
- Without the AWS provider, Terraform has no idea what aws_vpc or aws_subnet means
- The provider translates your HCL into actual AWS API calls
- Downloaded automatically when you run terraform init

## Provider Configuration
- region = which AWS region to deploy into
- default_tags = automatically applies tags to EVERY resource Terraform creates
- Never hardcode credentials in .tf files — Terraform picks them up from aws configure

## What is the State File?
- terraform.tfstate is Terraform's memory
- It records every resource Terraform created, its configuration, and its AWS ID
- When you run terraform plan, Terraform compares your .tf files against the state file
- If they match → no changes. If they differ → shows you exactly what will change.

## Why Local State is Dangerous
- No teamwork: teammate has no state file, Terraform creates duplicates
- No backup: laptop dies, state is gone, Terraform has no idea what it built
- No locking: two people apply at same time, state gets corrupted

## Remote State — The Solution
- Store state file in S3 so everyone shares the same state
- Use DynamoDB for locking so only one person can apply at a time
- One S3 bucket + one DynamoDB table for ALL your projects
- Each project gets a different key (file path) inside the bucket

## S3 Backend Block Explained
```hcl
backend "s3" {
  bucket         = "omar-chaalan-terraform-state" # which S3 bucket to use
  key            = "day2/terraform.tfstate"        # file path inside the bucket
  region         = "us-east-1"                     # region the bucket lives in
  dynamodb_table = "terraform-state-lock"          # DynamoDB table for locking
  encrypt        = true                            # encrypt state file at rest
}
```

## Why backend is not a resource
- resource tells AWS to build infrastructure
- backend tells Terraform how to behave (where to save state)
- backend lives inside terraform {} block — it is config for Terraform itself not AWS

## Terraform Labels vs AWS Console Names
- aws_vpc.main → your internal Terraform label, never changes
- Name = "day2-vpc-updated" → what shows in AWS console, changes when you update tags
- Renaming a Terraform label without moved block = Terraform destroys and recreates resource

## Key Commands
terraform init              # detects new backend, downloads providers
terraform plan              # compares code vs state, shows what will change
terraform apply             # builds infrastructure, updates state
terraform destroy           # tears down infrastructure
terraform state list        # list all resources Terraform is tracking
terraform state show <name> # show full details of one resource
terraform state pull        # display current state file contents

## State Locking Flow
1. You run terraform apply
2. Terraform writes lock record to DynamoDB
3. Terraform reads state from S3, makes changes, writes updated state back
4. Terraform deletes the lock record
5. If someone else applies during step 3 → they get locked out until you finish

## My Mistakes
- Used wrong bucket name (must be globally unique across ALL AWS accounts)
- Confused Terraform label (aws_vpc.main) with AWS console Name tag

## Important Rules
- Never commit terraform.tfstate to GitHub — add to .gitignore
- Change only the key in backend block for each new project folder
- Same S3 bucket and DynamoDB table used for all projects
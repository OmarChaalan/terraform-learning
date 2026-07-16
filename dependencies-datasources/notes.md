# Day 4 — Dependencies + Data Sources

## Implicit Dependencies
- Created automatically when one resource references another's attribute
- Example: vpc_id = aws_vpc.main.id inside a subnet — Terraform knows VPC must exist first
- Terraform builds a dependency graph, creates independent resources in parallel
- terraform graph — visualizes this (rarely needed day-to-day, good to know exists)

## Explicit Dependencies — depends_on
- Used when two resources are related but Terraform can't detect it through references
- Example: EC2 instance needs an IAM policy attached first, but no direct attribute link
- Use sparingly — if using it constantly, restructure to use real references instead

## Data Blocks — reading vs creating
- resource = creates and manages something in AWS
- data = reads something that already exists, never creates/destroys it
- Same bracket syntax, different keyword

## When to use data blocks (the real rule)
Ask: "Do I want Terraform to CREATE this, or just READ what's already there?"
- Create → resource
- Read → data

Four common real-world cases:
1. Dynamic AWS info that shouldn't be hardcoded (AZs, latest AMI, account ID)
2. Existing infra owned by someone else (shared VPC, existing bucket)
3. Account/identity context (building ARNs, tagging with account ID)
4. Integrating with infra outside your current Terraform state (default VPC)

## Key Data Sources Used Today
- aws_availability_zones — returns list of AZs available in the region right now
  → data.aws_availability_zones.available.names[0]
- aws_caller_identity — returns info about current AWS credentials (account_id, arn)
  → data.aws_caller_identity.current.account_id
  → data.aws_caller_identity.current.arn
- aws_ami — finds latest AMI matching filters instead of a hardcoded, stale AMI ID
  → data.aws_ami.amazon_linux.id
- aws_vpc (default = true) — reads AWS's built-in default VPC without managing it

## Backend Block Cannot Use Variables
- terraform { backend "s3" { region = var.region } } → ERROR: Variables not allowed
- Backend config is resolved BEFORE Terraform can process variables — chicken-and-egg problem
- Must hardcode literal values in the backend block: region = "us-east-1"
- One of very few places in Terraform where hardcoding is actually required

## Free Tier EC2 Gotcha (real issue hit today)
- t2.micro is NOT free-tier-eligible on newer AWS accounts (post July 2025 changes)
- Check what IS eligible on your specific account before assuming:
  aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true" 
    --query "InstanceTypes[].InstanceType" --output table --region us-east-1
- t3.micro is the common replacement, but always verify per-account

## terraform.tfvars — Confirmed Understanding
- variables.tf defines WHAT variables exist
- terraform.tfvars sets the actual VALUES
- Since every variable has a default AND is set in .tfvars, Terraform never prompts interactively
- Priority order: CLI -var flag > terraform.tfvars > default in variables.tf

## Commands Learned/Used Today
terraform state list                          # lists all resources AND data sources tracked
terraform state show <resource_or_data_name>   # shows full attribute detail of one item
terraform output                               # shows all output values without re-applying
terraform output <name>                        # shows one specific output
aws sts get-caller-identity                    # CLI equivalent of aws_caller_identity data source
aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true"  # check free tier eligibility

## Important Clarification
- terraform state list does NOT show "options" like available AZs to choose from
- It ONLY shows resources/data sources you've written blocks for and applied
- To see what a data source actually resolved to, use terraform state show or terraform output
- One data source block = one line in state list, regardless of how many values it internally returned

## My Mistakes Today
- Used var.region inside a backend block — not allowed, must be hardcoded
- Multiple hyphen/underscore mismatches between main.tf and outputs.tf — 
  now double-checking resource names match character-for-character before applying

## Important Rules
- Always run terraform destroy after practice — EC2 instances draw down free tier credits
- Root user should never be used for day-to-day CLI/Terraform work — create an IAM user
- Bucket/DynamoDB names must be recreated per-account if switching AWS accounts
- Account ID is the same across root and IAM users — it's tied to the account, not the user
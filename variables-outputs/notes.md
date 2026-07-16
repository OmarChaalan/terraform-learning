# Day 3 — Variables, Outputs + Locals

## Why Variables Exist
- Variables remove hardcoded values from your code
- Change a value in one place — updates everywhere automatically
- Without variables you hunt through 6 files to change one CIDR block
- With variables you change it once in .tfvars and everything updates

## Variable Types
- string  — any text: "us-east-1"
- number  — integer or float: 443
- bool    — true or false only
- list    — ordered collection: ["us-east-1a", "us-east-1b"]
- map     — key value pairs: { Owner = "omar", Env = "dev" }
- object  — structured data with named attributes of different types

## How to Reference Variables
- var.region         → references a variable
- var.list_name[0]   → first item in a list variable
- var.list_name[1]   → second item in a list variable
- Lists are zero-indexed — [0] is first, [1] is second

## Variable Validation
- Enforces rules on what values are acceptable
- Terraform rejects invalid values BEFORE touching any infrastructure
- Example: environment must be "dev", "staging", or "production" only
- If wrong value passed → shows your error_message and stops

## The 4 File Structure
- main.tf        → resources you are building
- variables.tf   → defines what variables exist
- locals.tf      → computed values you reuse
- outputs.tf     → values exposed after apply

## locals.tf — Computed Values
- Locals compute their value INSIDE Terraform from other values
- Variables get their value from OUTSIDE (you, .tfvars, CI/CD)
- Reference with local.name_prefix (singular local not locals)

## The difference between var and local
| | var | local |
|---|---|---|
| Value from | Outside — user, .tfvars, CI/CD | Inside — computed from other values |
| User can change? | Yes | No |
| Syntax | var.environment | local.name_prefix |

## Common locals pattern
- name_prefix = combines environment + region for consistent naming
  "${var.environment}-${var.region}" → "dev-us-east-1"
- common_tags = tags applied to every resource
- is_production = true/false flag for production-specific behavior

## default_tags vs merge()
- default_tags in provider → common tags applied automatically to ALL resources
- merge() → manually combine common tags + extra tags in each resource
- Both use local.common_tags — just applied in different places

## When to use each
- YOUR code from scratch → always use default_tags (cleaner, less work)
- Someone else's code with no default_tags → use merge() on each resource
- Need extra tags on ONE specific resource → just add them in resource tags block
  (they combine automatically with default_tags)

## outputs.tf
- Exposes values after terraform apply
- Three uses: print useful info, share between modules, share between projects
- terraform output              → show all outputs
- terraform output vpc_id       → show specific output
- terraform output -raw vpc_id  → raw value for use in Bash scripts

## .tfvars File
- Sets actual values for your variables
- variables.tf defines what variables EXIST
- terraform.tfvars sets the actual VALUES
- Never change variables.tf to set values — use .tfvars
- Terraform automatically loads terraform.tfvars if it exists

## Three Ways to Pass Variables
- .tfvars file    → terraform apply -var-file="production.tfvars"
- Command line    → terraform apply -var="environment=staging"
- Env variables   → export TF_VAR_environment="production"

## Sensitive Variables
- sensitive = true hides value in plan and apply output
- Shows (sensitive value) instead of real value
- Never appears in logs accidentally
- Pass via: export TF_VAR_db_password="yourpassword"
- Use this for RDS passwords, API keys, secrets

## String Interpolation
- Embed a value inside a string using ${}
- "${local.name_prefix}-vpc" → "dev-us-east-1-vpc"
- "${var.environment}-subnet" → "dev-subnet"

## My Mistakes
- Confused local.common_tags with default_tags — they work together,
  local.common_tags is the SOURCE, default_tags is where it gets APPLIED
- Confused merge() with default_tags — merge() is for codebases 
  that don't use default_tags

## Important Rules
- terraform.tfvars goes in .gitignore — never commit it
- Always write description on every variable
- Zero hardcoded values in main.tf — everything is a variable
- default_tags in provider = cleaner than merge() on every resource

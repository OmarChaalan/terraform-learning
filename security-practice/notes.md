# Security Best Practices

## Why This Matters
- Bots scan public GitHub repos for exposed AWS keys within minutes of a push
- A leaked key can mean someone else spinning up crypto-mining infrastructure
  on my account before I even notice
- This isn't advanced/optional — it's baseline expected knowledge

## Rule 1 — Never Hardcode Secrets
- Never write real passwords/keys directly in .tf files
- Even if the file never gets pushed to GitHub, the value STILL ends up
  in the Terraform state file, in plain text, stored in S3

## sensitive = true — What It Actually Does (and Doesn't)
- ONLY hides the value from console/log output (terminal, terraform apply output)
- Does NOT encrypt the value
- Does NOT hide it from the state file — the real value is still sitting there
  in plain text in S3, regardless of this flag
- Real security boundary = who can access the S3 state bucket, not this flag
- This flag protects against: accidental screen-sharing, CI/CD log leaks,
  someone glancing at your terminal
- Simple mental model: like writing "[hidden]" on a whiteboard instead of
  the real answer — the teacher (Terraform) still knows the real value
  internally, it's purely a DISPLAY setting

## Sensitivity "Spreads" Automatically
- If an output/value is built using ANY sensitive data, Terraform automatically
  treats the RESULT as sensitive too, by default — even if the result itself
  reveals nothing (e.g., a true/false check)
- Can override this explicitly with sensitive = false when the actual output
  is genuinely safe to show, even though it was calculated FROM sensitive data
- Example: length(sensitive_value) > 0 → the true/false result reveals nothing
  about the actual value, so marking it sensitive = false is correct and safe

## AWS SSM Parameter Store
- Free (standard tier), stores secrets OUTSIDE Terraform code entirely
- Created ONCE, manually, via CLI — not repeatedly through Terraform
- --type "SecureString" = AWS encrypts it at rest using KMS automatically
- Read into Terraform via a data source (same data pattern as Day 4) —
  Terraform fetches the current value at plan/apply time, but the secret
  text never appears in .tf files or git history
- Naming convention I control: /owner/environment/secret-name
  (e.g. /omar/dev/db_password) — just needs to start with /
- One parameter per distinct secret — if 3 environments each have their own
  DB password, that's 3 separate parameters
- Can make the path itself dynamic: name = "/omar/${var.environment}/db_password"
  → same Terraform code automatically reads the right secret per environment

## AWS Secrets Manager — the Alternative
- Adds: automatic rotation (scheduled password changes), native RDS integration
- Costs ~$0.40/secret/month vs SSM Standard which is free
- Default choice: SSM Parameter Store, unless a job specifically needs
  auto-rotation

## KMS Encryption for State (Concept Learned)
- Default S3 encryption (what I already have) = AWS-managed key,
  ANYONE with S3 read access to the bucket can decrypt
- Customer-managed KMS key = adds a SEPARATE permission layer —
  S3 access alone isn't enough, also need explicit KMS decrypt permission
  via a key policy
- One KMS key CAN be reused across multiple projects/buckets — no 1-to-1
  requirement. Same logic as reusing one DynamoDB lock table across projects
- When separate keys make sense: when different environments need genuinely
  different sets of people who can decrypt (e.g., prod restricted to senior
  engineers, dev open to whole team)
- Real value of KMS isn't just "turning it on" — it's writing the key policy
  that controls exactly WHO can decrypt
- Decision: understood the concept and tradeoffs deeply enough to explain
  in an interview: skipped full implementation today due to time, revisit
  if time allows before Week 3 portfolio project

## Least-Privilege IAM — The Underlying Philosophy
- Give every user/role/service EXACTLY the permissions needed, nothing more
- Bad: Action = "*", Resource = "*" → if credentials leak, damage is total
- Good: scoped Action list + specific Resource ARN → if credentials leak,
  blast radius is tiny
- I already applied this practically weeks ago without naming it — using
  a scoped IAM user (omar-chaalan) instead of root for all CLI/Terraform work

## Outputs Built Today — Two Different Protection Strategies
output "password_was_retrieved" {
    value = length(data.aws_ssm_parameter.db_password.value) > 0
    sensitive = false   # overriding Terraform's auto-sensitivity guess,
                        # since true/false reveals nothing about the real password
}

output "db_password" {
    value = data.aws_ssm_parameter.db_password.value
    sensitive = true    # this one shows the REAL value, so needs real protection
}

- Strategy 1: TRANSFORM the sensitive value into something safe to show
  (length() > 0 → just a boolean, reveals nothing)
- Strategy 2: show the REAL value but mark it protected (sensitive = true)
- Which to use depends on whether I actually need the raw value downstream,
  or just need to CONFIRM something worked

## Things I Had to Ask About
- Initially unclear that sensitive = true only affects DISPLAY, not the
  state file itself — real state file always has the true, unmasked value
- Didn't understand why password_was_retrieved needed sensitive = false
  explicitly — didn't realize sensitivity "spreads" automatically from
  anything it's calculated from, even if the result itself is harmless

## AWS CLI Commands

### SSM Parameter Store
# Create a parameter (one-time, manual, NOT run repeatedly via Terraform)
aws ssm put-parameter \
  --name "/omar/dev/db_password" \
  --value "MyRealSecurePassword123!" \
  --type "SecureString" \
  --region us-east-1

# Update an existing parameter's value
aws ssm put-parameter \
  --name "/omar/dev/db_password" \
  --value "NewPassword456!" \
  --type "SecureString" \
  --overwrite \
  --region us-east-1

# Read a parameter's value directly via CLI (for checking, not for Terraform)
aws ssm get-parameter \
  --name "/omar/dev/db_password" \
  --with-decryption \
  --region us-east-1

# Delete a parameter when done practicing
aws ssm delete-parameter --name "/omar/dev/db_password" --region us-east-1

### Secrets Manager (alternative to SSM)
aws secretsmanager create-secret \
  --name "omar/dev/db_password" \
  --secret-string "MyRealSecurePassword123!" \
  --region us-east-1

### KMS (concept learned, commands for reference/later use)
# Create a customer-managed key
aws kms create-key \
  --description "Terraform state encryption key" \
  --region us-east-1

# Create a friendly alias for the key
aws kms create-alias \
  --alias-name alias/terraform-state-key \
  --target-key-id <KEY_ID> \
  --region us-east-1

# Set a key policy controlling exactly who can decrypt
aws kms put-key-policy \
  --key-id <KEY_ID> \
  --policy-name default \
  --policy '{...}' \
  --region us-east-1

# Schedule key deletion (mandatory 7-30 day waiting period, safety measure)
aws kms schedule-key-deletion --key-id <KEY_ID> --pending-window-in-days 7 --region us-east-1

## Key Takeaway
Today wasn't about learning new Terraform SYNTAX so much as learning a way
of THINKING about infrastructure — assume anything you build might leak,
and design so that a leak causes minimal damage. sensitive = true, SSM,
and least-privilege IAM are all different tools pointed at that same
underlying principle.
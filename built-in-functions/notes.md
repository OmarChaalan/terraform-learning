# Day 5 — Built-in Functions

## Why Functions Exist
- Terraform has no if/else or general loops like a real programming language
- Functions are how you transform, combine, and format data instead
- Each function exists to solve one specific real problem — not learned for their own sake

## The 5 I Actually Need to Know Deeply

### merge()
- Combines two or more maps into one
- If a key exists in both maps, the LATER map wins
- Solves: repeating the same tags (Environment, Owner, ManagedBy) on every single resource
- Used in: built-in-functions/main.tf — merge(local.common_tags, { Purpose = "day5-practice" })
- Note: default_tags in the provider block does this automatically for ALL resources —
  merge() is for when default_tags isn't set up, or when ONE resource needs extra tags
  beyond the common set

### lookup()
- Three arguments: lookup(map, key, default_value)
- Safely reads a value from a map, with a fallback if the key doesn't exist
- Solves: Terraform crashing completely when a key (like an environment name) is missing
- Used in: built-in-functions/main.tf — 
  lookup(var.storage_tier_map, var.environment, "standard")
- Without the fallback, deploying to an environment not in the map = hard failure

### toset()
- Converts a list into a set (sets auto-remove duplicates)
- Solves: for_each REQUIRES a set or map as input — it rejects plain lists
- My variables are defined as list(string), so toset() wraps them before for_each uses them
- Used in: built-in-functions/main.tf — for_each = toset(var.bucket_purposes)
- Inside the loop, each.value = the current item ("logs", then "backups")
- This creates MULTIPLE resources from ONE resource block — huge for avoiding
  copy-pasted duplicate blocks (this replaces my Day 1 pattern of writing
  public_subnet_1 and public_subnet_2 as two separate blocks)

### templatefile()
- Two arguments: templatefile(file_path, {map of values to inject})
- Reads a file, finds ${...} placeholders inside it, substitutes real values
- Solves: needing to inject dynamic values (like environment name) into a script
  without hardcoding a giant string directly inside main.tf
- Used in: 
  - ec2-basics/main.tf (Day 6) — real EC2 user data, deployed and tested with curl
  - built-in-functions/locals.tf — rendered_script practice example
- path.module = "the folder this .tf file is in" — makes the file path portable

### jsonencode()
- Converts normal HCL (maps/lists) into the raw JSON string AWS actually requires
- Solves: IAM policies are natively JSON (AWS's own format, not Terraform's choice) —
  without this you'd hand-write raw JSON strings with zero syntax help, easy to break
- Used in: built-in-functions/main.tf — aws_iam_policy.s3_read_only
- Write clean structured HCL, jsonencode() does the conversion for you
- IMPORTANT: once encoded, the result is a STRING — cannot run map functions like
  merge() on it anymore. Do all merging in HCL first, encode LAST.

## The One Fixed Pattern (not a 6th function to master)
base64encode(templatefile(...))
- AWS requires EC2 user data specifically in base64 format — an AWS API rule, not optional
- Always appears as this exact combo when building EC2 user data
- Don't need to deeply understand base64encode() on its own — just recognize this SHAPE
- Used in: ec2-basics/main.tf (Day 6)

## Quick Reference Table

| Function | Solves | Where I used it |
|---|---|---|
| merge() | Repeated tags everywhere | built-in-functions bucket tags |
| lookup() | Missing key crashes deploy | storage_tier_map lookup |
| toset() | for_each rejects plain lists | purpose_buckets loop |
| templatefile() | Inject variables into scripts | ec2-basics user_data (real) |
| jsonencode() | AWS requires JSON, not HCL | s3_read_only IAM policy |

## terraform console — testing functions before using them
terraform console
> merge({a = 1}, {b = 2})
> lookup({dev = "x"}, "dev", "fallback")
> toset(["a", "b", "a"])
exit

## My Mistakes / Things to Remember
- Functions are NOT variables — a variable holds a value I provide,
  a function transforms/computes a value
- for_each creates a MAP of resources, not a single resource —
  to read outputs from it I need a for expression:
  [for key, val in aws_s3_bucket.purpose_buckets : val.id]
- git add on an already-committed folder shows "nothing added" — not an error,
  just means no new changes since last commit
- "main has no upstream branch" fix: git push --set-upstream origin main
  (only needed once per fresh situation, then normal git push works again)

## Commands Used Today
terraform console                              # test functions without deploying
git log --oneline --stat -- folder-name/        # see which commit(s) touched a folder
git push --set-upstream origin main             # fix missing upstream branch error

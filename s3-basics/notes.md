# Day 12 — S3 Basics in Terraform

## The Core Resource
resource "aws_s3_bucket" "example" {
  bucket = "my-unique-bucket-name"
}
- One required argument. Already written this pattern several times
  (Day 5, Day 10) without realizing it was "the S3 basics."

## Bucket Naming Rule
- S3 bucket names are GLOBALLY UNIQUE across every AWS account on Earth,
  not just my own
- Lowercase only, no underscores, no uppercase
- lower() from Day 5 guarantees compliance regardless of variable content
- Already hit BucketAlreadyExists twice this week (state bucket, security-practice) —
  practical defense: add something unique to me (name/suffix) to the bucket name

## The "Separate Resource Per Sub-Configuration" Pattern
- Versioning, encryption, public access block are each their OWN resource,
  linked back via bucket = aws_s3_bucket.example.id
- Not arbitrary complexity — mirrors how S3 itself works: bucket is one API
  object, but versioning/encryption/policy are independently-toggleable
  settings underneath it
- Will see this same pattern repeated constantly with S3 in Terraform

## Versioning
resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}
- Default S3 behavior: uploading to the same path OVERWRITES permanently, no undo
- With versioning: overwrite creates a NEW version, old one stays accessible
  (until explicitly deleted)
- Needed before portfolio project's state bucket pattern and any bucket
  holding files I can't afford to lose

## Encryption at Rest — What I Actually Gain
- "At rest" = encrypted while sitting on AWS's physical disks, not moving
  (different from "in transit" which HTTPS handles separately)
- Real-world threat model: protects against theoretical physical/low-level
  storage access
- PRACTICAL reason it matters: many compliance frameworks (SOC 2, HIPAA,
  PCI-DSS) REQUIRE encryption at rest as a checkbox — real employers care
  about this regardless of how likely the physical-access threat is
- When to use: ALWAYS, by default, every bucket — no real downside,
  AES256 is free and automatic

## The 3 Real SSE Options (corrected — NOT including RSA, that was wrong)
1. SSE-S3 (sse_algorithm = "AES256")
   - AWS manages keys entirely, automatically, FREE
   - No control/visibility into the keys themselves
   - Right default for most buckets, including portfolio project

2. SSE-KMS (sse_algorithm = "aws:kms")
   - I control the key — same customer-managed KMS concept as Day 10,
     applied to S3 objects instead of Terraform state
   - Costs a bit (KMS charges per API call)
   - Gains: audit trail via CloudTrail (every use logged), access control
     via key policy
   - Use when I need to PROVE who accessed encrypted data, or restrict
     decrypt beyond normal S3 permissions

3. SSE-C (customer-provided keys)
   - I provide my own key with EVERY request, AWS never stores it
   - Rare in practice — I'm fully responsible, lose the key = data
     permanently unrecoverable, even AWS can't help
   - Not typically configured in Terraform for standard use cases

## The 4 Public Access Block Settings — What Each Actually Does
- Two mechanisms exist for granting public access: ACLs (older, legacy) 
  and Bucket Policies (modern, jsonencode() based)
- Each mechanism has a "prevent new" setting and a "neutralize existing" setting:

block_public_acls       → prevents NEW public ACLs from being created
                           (doesn't touch ACLs that already exist)
ignore_public_acls       → ACTIVELY IGNORES any public ACLs that already
                           exist, even pre-dating this setting
block_public_policy      → prevents attaching a NEW public bucket policy
restrict_public_buckets  → if a public policy somehow exists anyway,
                           restricts access to only AWS services/authorized
                           users WITHIN my own account — neutralizes it

- Simple model: ACLs and Policies are the 2 mechanisms, each gets a
  "block new" + "neutralize existing" pair = defense in depth / belt
  and suspenders
- All 4 = true is the safe default for almost every bucket

## Bucket Policy Example — What It Actually Does
resource "aws_s3_bucket_policy" "app_data" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = { AWS = aws_iam_role.github_actions.arn }
      Action = ["s3:GetObject", "s3:PutObject"]
      Resource = "${aws_s3_bucket.app_data.arn}/*"
    }]
  })
}
- Plain English: "Allow whoever is identified by this specific IAM role's
  ARN to download and upload objects, but ONLY within this one bucket"
- github_actions used as principal because it's a real existing resource
  from Day 11 — realistic scenario: CI/CD pipeline needing to upload
  build artifacts/deployment files to this bucket
- Same least-privilege principle as Day 10, applied to "which identity
  can touch which bucket"
- If no real reason for a specific identity to access a bucket, just
  skip the bucket policy entirely — own IAM user already has broad access

## HTTP/API Verbs → S3 Actions (refresher)
GET    → s3:GetObject     — retrieve/read a file
PUT    → s3:PutObject     — create or fully replace a file
HEAD   → (shares GetObject permission) — fetch only METADATA
          (size, last-modified, content-type), not the actual content —
          "does this exist, what does it look like" without downloading
DELETE → s3:DeleteObject  — remove a file
POST   → less common for basic Terraform IAM policies, more relevant to
          browser-based upload forms
LIST (S3-specific, not raw HTTP) → s3:ListBucket — see WHAT'S in a bucket
- IMPORTANT DISTINCTION: ListBucket (see what exists) is a DIFFERENT
  permission from GetObject (read actual content) — can grant one
  without the other. Common interview trip-up point.

## Uploading Objects via Terraform
resource "aws_s3_object" "readme" {
  bucket = aws_s3_bucket.app_data.id
  key    = "README.md"
  source = "${path.module}/README.md"
  etag   = filemd5("${path.module}/README.md")
}
- key = the object's path/filename INSIDE the bucket
- source = local file path to upload
- etag = filemd5(...) — computes MD5 hash of local file content, lets
  Terraform detect if the file CHANGED since last apply
- Without etag: Terraform either always re-uploads (wasteful) or never
  notices changes (stale) — genuine common gotcha
- Alt pattern: content + md5() instead of source + filemd5() — for
  writing inline text directly instead of managing a separate file
- Honest use case: most real infra work manages the BUCKET and POLICIES,
  not individual uploads — application code usually handles uploads at
  runtime, not Terraform. Real Terraform use case for me: uploading
  compiled frontend files for the portfolio project once built.

## Verification Commands
aws s3api get-bucket-versioning --bucket <bucket-name>
aws s3api get-bucket-encryption --bucket <bucket-name>
aws s3api get-public-access-block --bucket <bucket-name>
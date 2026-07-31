# Day 11 — GitHub Actions CI/CD (Went Deep, Not Lighter Bar)

## The Core Concept — CI/CD in Plain Terms
- CI (Continuous Integration) = automatically CHECK a change is good before anyone uses it
- CD (Continuous Deployment) = automatically APPLY it once checked/approved
- GitHub Actions = the robot that runs the checklist (workflow file) I write
- The robot only does MECHANICAL checks (syntax valid? formatted right? what would change?)

## Branches, Main, Push vs Pull Request
- Branch = a separate parallel copy of the repo to make changes without affecting main
- main = just the CONVENTIONAL NAME for the "official" branch — not a magic keyword
- Push = uploading my local commits to GitHub — NO approval needed, just happens
  (this is all I've done all week, direct to main)
- Pull Request (PR) = a PROPOSAL: "please review these changes on my branch before
  merging into main" — the actual review/safety checkpoint
- Pipeline = general term for the whole automated sequence (GitHub calls it "workflow")

## Where the Workflow File Lives
.github/workflows/terraform.yml
- Folder path is FIXED — GitHub only scans here
- Filename inside can be anything

## The Trigger → Run Connection
on:
  pull_request:
    branches: [main]    → runs when a PR targeting main is opened/updated
  push:
    branches: [main]    → runs when code actually lands on main (e.g. after a merge)
- Opening the PR itself IS the trigger — no manual button press needed
- Same workflow file runs TWICE at different moments for different reasons:
  once on PR open (→ reaches plan + comment), once on merge/push (→ reaches apply)
- if: conditions on individual STEPS control which parts actually execute,
  depending on which event fired the whole workflow

## Why Plan-on-PR, Apply-on-Merge Split Matters
- This IS the safety mechanism, not just organization
- Apply is structurally impossible to trigger from a PR review alone —
  it only fires after code has actually landed on main

## OIDC — Why It Exists and How It Actually Works
THE PROBLEM: GitHub's runner is a brand new, disposable machine every run —
zero prior relationship with my AWS account, no stored credentials.

OLD WAY (risky): paste long-lived AWS Access Key + Secret into GitHub Secrets.
Risk: never expires on its own, if ever leaked = standing access indefinitely.

OIDC WAY (modern, correct):
1. GitHub generates a short-lived signed token: "I am GitHub Actions, running
   from EXACTLY this repo, this run only"
2. Workflow presents token to AWS STS: "here's proof of who I am, give me
   temporary credentials"
3. AWS checks: do I have a trust policy that trusts tokens from this repo?
   (configured once, in advance, via aws_iam_openid_connect_provider)
4. If trust passes, AWS issues TEMPORARY credentials (~1hr), tied to a
   specific IAM role, with only that role's permissions
- KEY INSIGHT: nothing long-lived ever sits in GitHub. No static secret to leak
  because there IS no static secret.

## The OIDC Terraform Resources (built in oidc/ folder, applied for real)
aws_iam_openid_connect_provider:
- url = GitHub's token-issuing service — AWS only trusts tokens from here
- client_id_list = ["sts.amazonaws.com"] = the "audience" the token is meant for
- thumbprint_list = cert thumbprint verifying GitHub's signing cert is legit
  (known published value, not self-generated)

aws_iam_role (github_actions):
- assume_role_policy defines WHO can assume this role and under what condition
- THE REAL SECURITY BOUNDARY:
  "token.actions.githubusercontent.com:sub" = "repo:OmarChaalan/terraform-learning:*"
  → only tokens whose subject claim matches THIS EXACT repo are trusted
  → a workflow from someone else's repo, even using the same OIDC provider,
    gets rejected here
- Must match GitHub username/repo name EXACTLY, case-sensitive

aws_iam_role_policy_attachment:
- PowerUserAccess used for practice — real production would scope this
  much tighter (least-privilege, same Day 10 principle applied to what
  the PIPELINE is allowed to do)

## permissions: Block in the Workflow — Why It's Needed
permissions:
  id-token: write     → without this, the workflow literally CANNOT generate
                         the OIDC token at all — this is what makes the whole
                         mechanism possible
  contents: read      → permission to check out repo files
  pull-requests: write → needed to post the plan comment on a PR

## uses: vs run: in Workflow Steps
- uses: → use a pre-built, reusable action someone else wrote
  (actions/checkout@v4, hashicorp/setup-terraform@v3, aws-actions/configure-aws-credentials@v4)
- run: → execute a literal shell command directly
  (terraform init, terraform plan -no-color, terraform apply -auto-approve)

## The Comment Plan on PR Step — Line by Line
if: github.event_name == 'pull_request'
  → gatekeeper: skip entirely if triggered by a push instead (no PR exists
    to comment on in that case)
uses: actions/github-script@v7
  → lets me write real JavaScript to call GitHub's own API
${{ steps.plan.outputs.stdout }}
  → bridges back to the earlier step (id: plan) and grabs its actual text output
github.rest.issues.createComment({...})
  → the actual API call. PRs are internally treated as a type of "issue" in
    GitHub's API (historical quirk) — hence issues.createComment even
    though it's commenting on a PR

## The Terraform Apply Step — Line by Line
if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  → BOTH conditions must be true (&&): branch is main AND event is a push
  → in normal PR flow, this combination only genuinely happens at the moment
    of merge
-auto-approve
  → skips the interactive "type yes" prompt since nobody's at a terminal
    to type it

## YAML Syntax — Real Mistakes I Made and Fixed
- Every key needs a colon, even with nested content below:
  WRONG: pull_request  →  RIGHT: pull_request:
- push_request is NOT a real GitHub event — correct keyword is just push
  (matches the concept: push doesn't need approval/request, it just happens)
- Indentation IS the structure in YAML, not just style — runs-on and steps
  must be indented FURTHER IN than the job name they belong to, or YAML
  doesn't understand they're nested inside it
- hashicorp/set-terraform → typo, correct is hashicorp/setup-terraform

## Real Debugging Story #1 — Orphaned State Lock (happened TWICE)
- Symptom: workflow stuck 20+ min in "plan" phase, no visible progress
- Diagnosis: aws dynamodb scan on terraform-state-lock table, filtered by path
- Found: real lock entry (no -md5 suffix) held by "runner@runnervm..." —
  confirmed it was MY OWN cancelled/interrupted run, not external conflict
- Root cause: a cancelled/killed workflow run doesn't always get the chance
  to run Terraform's own cleanup code that releases the lock gracefully
- Fix: cancel the stuck run on GitHub first, then manually delete the
  specific orphaned lock item:
  aws dynamodb delete-item --table-name terraform-state-lock \
    --key '{"LockID": {"S": "omar-chaalan-terraform-state/modules-practice/terraform.tfstate"}}' \
    --region us-east-1
- ALWAYS verify with a fresh scan afterward before trying anything else

## Real Debugging Story #2 — Interactive Variable Prompt Hang
- Symptom: looked identical to the lock hang from outside (just "sitting there")
  but was a COMPLETELY different root cause
- Real cause: var.my_ip has no default (intentional, from Day 7) — locally this
  is fine because I'm sitting at the terminal to answer the prompt. On GitHub's
  runner, NOBODY is there to answer — it waits forever for input that never comes
- How I found it: expanded the live log of the stuck step directly (not just
  watching the clock) — saw it frozen on the literal line "var.my_ip"
- KEY LESSON: automated pipelines can NEVER rely on interactive input —
  everything needed must be supplied explicitly, upfront
- Fix: GitHub repo Secret (TF_VAR_MY_IP) + env: block on both the Plan and
  Apply steps:
  env:
    TF_VAR_my_ip: ${{ secrets.TF_VAR_MY_IP }}
- Terraform automatically reads any TF_VAR_ prefixed environment variable —
  no extra parsing needed, same mechanism from Day 3

## Real Mistake — Deleting Workflow Run History
- "Delete workflow run" in the Actions tab deletes the LOG/RECORD of a past
  run — does NOT delete the workflow file, does NOT undo what that run did
- I deleted run records before checking their outcome, which meant I couldn't
  see whether my fixes had actually worked or not — had to verify actual
  AWS state directly instead (terraform state list) rather than trust the
  now-incomplete Actions history
- LESSON: don't delete run history until confirmed I don't need to reference
  what happened — the Actions log is diagnostic evidence, not just clutter

## How to Distinguish "Actively Working" vs "Genuinely Hung"
- Don't just watch the clock/spinner — click into the specific step and
  check if NEW TEXT is actively appearing/updating in the live log
- Frozen on the same line with zero new output for several minutes = hung,
  worth investigating/cancelling
- Actively scrolling new output, even slowly = genuinely working, worth
  waiting a bit longer

## AWS CLI Commands

### Checking for state locks (used constantly today)
aws dynamodb scan --table-name terraform-state-lock --region us-east-1 \
  --filter-expression "contains(LockID, :path)" \
  --expression-attribute-values '{":path":{"S":"modules-practice"}}'

### Deleting a specific orphaned lock
aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "omar-chaalan-terraform-state/modules-practice/terraform.tfstate"}}' \
  --region us-east-1

### Confirming what actually exists vs what state thinks exists
terraform state list   # run this instead of trusting deleted/incomplete
                        # Actions history when unsure what really happened
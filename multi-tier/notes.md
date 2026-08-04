# ALB + RDS Mini-Lesson, Then Multi-Tier Practice

## Why This Was Structured This Way
- Originally, ALB and RDS had zero standalone Terraform teaching before
  appearing in project days — this restructure fixed that gap without
  adding new days: teach syntax first, immediately build with it same session

## ALB in Terraform — 4 Connected Resources, Not One Block
Load Balancer → Target Group → Listener → (Target Group Attachment)
- Each piece has a distinct job, all reference each other via ARNs

## The ALB Resource
resource "aws_lb" "main" {
  internal           = false   # false = internet-facing, true = only reachable from inside VPC
  load_balancer_type = "application"  # Layer 7 (HTTP/HTTPS). "network" = Layer 4
  subnets            = [for s in aws_subnet.public_subnet : s.id]
}
- Internet-facing ALB MUST sit in PUBLIC subnets — needs to be reachable
  from outside

## Target Group + Health Checks — The Actual Mechanism
resource "aws_lb_target_group" "app" {
  health_check {
    path                = "/"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }
}
- ALB periodically GETs the path; matcher = "200" means HTTP 200 = healthy,
  anything else = unhealthy
- 2 consecutive successes needed to mark healthy, 2 consecutive failures
  to mark unhealthy and pull from rotation
- THIS is the actual mechanism providing high availability — broken
  instances stop receiving real traffic automatically

## Listener — Connects ALB to Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
- "Listen on port X, forward to this target group by default"
- Real production often adds HTTPS listener (443) + HTTP listener that
  REDIRECTS to HTTPS instead of forwarding directly (not built today,
  worth knowing exists)

## Target Group Attachment — Connecting EC2 Instances
resource "aws_lb_target_group_attachment" "app" {
  for_each = aws_instance.app_server   # loops over instances, not a set
  target_id = each.value.id
}
- Target group doesn't automatically know about EC2 instances —
  must attach explicitly
- for_each over the instance MAP (created with its own for_each) attaches
  all of them in one block, regardless of count

## RDS in Terraform

### DB Subnet Group — Mandatory Prerequisite
resource "aws_db_subnet_group" "main" {
  subnet_ids = [for s in aws_subnet.private_subnet : s.id]
}
- RDS requires this explicitly — can't skip it
- ALWAYS private subnets — database should never be directly internet-reachable

### The RDS Instance
resource "aws_db_instance" "main" {
  password = data.aws_ssm_parameter.db_password.value   # Day 10 lesson, applied for real
  db_subnet_group_name   = aws_db_subnet_group.main.name  # need .name, not the whole resource
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  backup_retention_period = 7      # or 0 for practice = no automated backups
  skip_final_snapshot     = true   # practice only — see tradeoff below
}
- Security architecture: private subnets (via subnet group) + private_sg
  attached = only EC2 instances with private_sg can reach it, nothing
  from the internet

### skip_final_snapshot Tradeoff
- true: terraform destroy works immediately, no final snapshot required
- false (real production default): destroy REFUSES without first creating
  a final snapshot — genuine safety feature
- Practice work being torn down anyway → true is fine
- Real production database → should be false

### RDS Cost Warning
- NOT automatically free-tier the same way VPC/S3 basics are
- db.t3.micro has its own separate free tier hour allowance (~750 hrs/mo,
  similar structure to EC2 but separate)
- Storage/backup costs apply beyond that
- Same destroy discipline as NAT Gateways — don't leave running

## Reusing the VPC Module for Real, First Time
- This was the actual payoff of Day 8's module work — modules/vpc called
  from a genuinely larger, more complex project for the first time
- Every root folder calling the module needs its OWN variables.tf and
  locals.tf — the module has zero visibility outside itself (confirmed
  understanding from earlier questions this session)
- Module receives common_tags as an INPUT, doesn't compute it — caller
  must always supply via its own locals.tf

## AWS CLI Commands
# Create SSM parameter for practice DB password (one-time, manual)
aws ssm put-parameter \
  --name "/omar/dev/multi-tier-db-password" \
  --value "PracticeDbPassword123!" \
  --type "SecureString" \
  --region us-east-1

# Clean up after practice
aws ssm delete-parameter --name "/omar/dev/multi-tier-db-password" --region us-east-1

# Test the deployed ALB
curl http://$(terraform output -raw alb_dns_name)

## Key Takeaway
Today combined nearly everything from the last 2 weeks into one real,
working system for the first time — and the bugs I hit were entirely
about REFERENCING things correctly (missing .name, missing var., wrong
argument count), not about misunderstanding the architecture itself.
That's a good sign: the concepts are solid, the remaining gap is
precision in how I write references — which is exactly the kind of
thing that gets sharper with more reps, starting tomorrow with the
real portfolio project.
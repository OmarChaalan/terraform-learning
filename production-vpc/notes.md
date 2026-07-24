# Day 7 — Practice: Full Production VPC

## Goal
Build a complete, production-style VPC from scratch using everything from Week 1 —
no new concepts today, just applying variables, locals, dependencies, data sources,
functions, and proper network architecture together in one real build.

## Architecture Built
- 1 VPC (10.0.0.0/16)
- 2 public subnets across 2 AZs (10.0.1.0/24, 10.0.2.0/24)
- 2 private subnets across 2 AZs (10.0.3.0/24, 10.0.4.0/24)
- 1 Internet Gateway
- 1 NAT Gateway + Elastic IP
- 2 route tables (public + private), each with correct associations
- 1 security group (web-facing: HTTP, HTTPS, SSH from my IP only)

## Public vs Private Subnet — The Real Difference
- Public subnet: route table sends 0.0.0.0/0 → Internet Gateway
  → bidirectional. Internet can reach in (if SG allows), instance can reach out.
- Private subnet: route table sends 0.0.0.0/0 → NAT Gateway
  → one-directional. Instance can reach OUT (updates, API calls),
  nothing from the internet can initiate a connection IN.
- map_public_ip_on_launch = true on public subnets, false on private — controls
  whether instances launched there get a public IP automatically

## NAT Gateway — Key Facts
- MUST live in a PUBLIC subnet — needs its own internet access via the IGW
  to forward traffic on behalf of private resources
- Needs an Elastic IP (aws_eip) attached — that's its public-facing address
- depends_on = [aws_internet_gateway.main] used here — genuine case where
  Terraform can't reliably auto-detect the ordering requirement through
  implicit references alone (NAT Gateway can fail to provision correctly
  if IGW isn't fully attached first)
- COST WARNING: ~$0.045/hour just for existing, whether used or not.
  Single most expensive thing in the plan so far — always destroy after practice.

## Syntax Mistakes I Made
- route = { } is WRONG — route is a nested block, not an assigned map
  Correct: route { cidr_block = "..."; gateway_id = "..." }
  (same pattern as ingress { } and egress { } blocks)

## Private Subnet Security — Design Principle
- Private-subnet resources should NOT accept traffic from 0.0.0.0/0 at all
- Instead, reference another security group directly as the source:
  ingress {
    security_groups = [aws_security_group.web_sg.id]
  }
- This means "only things with web_sg attached can reach this" — regardless
  of IP address. More precise than CIDR-based rules.
- This is the exact pattern I'll need for real when RDS goes into private
  subnets in the Week 3 portfolio project (Day 17)

## for_each + toset() — Deliberately Skipped Today
- Chose to write 2 separate subnet blocks (public_subnet_1, public_subnet_2)
  instead of forcing for_each before its real lesson on Day 9
- Same final infrastructure either way — for_each just reduces repetition,
  doesn't change what gets built
- Revisit this VPC (or build a fresh one) using for_each as practice
  once Day 9 properly explains it

## Commands Used
terraform init / plan / apply / destroy     # standard workflow
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<id>" 
  --query "RouteTables[*].Routes" --output table   # verify routing before testing anything else
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=<id>"
  --query "InternetGateways[*].{ID:InternetGatewayId,State:Attachments[0].State}"
  --output table                              # confirm IGW exists and is attached
aws ec2 describe-network-acls --filters "Name=vpc-id,Values=<id>"
  --query "NetworkAcls[*].Entries" --output json   # check for NACL Deny rules blocking traffic

## Debugging Order That Actually Works (learned this the hard way on Day 6)
1. Confirm instance/resource is actually running
2. Confirm route table exists AND is associated with the right subnet
3. Confirm security group rules are correct
4. Check NACLs last (default allows everything, rarely the issue, but exists)
5. Test with curl -v BEFORE a browser — gives more precise error info than
   a browser's generic "site cannot be reached"

## Key Takeaway
Architecture understanding was solid throughout — every bug today was a typo, not a misunderstanding of how
VPCs, routing, or security groups actually work. That gap closes with reps.
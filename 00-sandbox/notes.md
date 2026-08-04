/*

*** terraform.tfstate file
- Never edit it manually, you'll corrupt it and Terraform loses track of your infrastructure.
- Never commit it to GitHub / Use .gitignore
.gitignore:
# .gitignore
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfvars
.terraform.lock.hcl


#-----VPC SECTION-----#

*** enable_dns_support in a vpc
always true. You'd only set this to false in very specific security-locked environments. Never turn it off for normal work.
When this is true, that DNS server is active and your EC2 instances can use it to resolve domain names. 
When it's false, there's no DNS inside your VPC at all — your instances can't resolve google.com or any AWS service endpoint.

*** enable_dns_hostnames in a vpc
This builds on top of enable_dns_support. It tells AWS to assign a DNS hostname to every EC2 instance you launch in the VPC.
Without it, your EC2 instance has an IP address but no hostname. With it, your instance gets something like:
You need this for two important things. First, RDS — when you create an RDS database, 
AWS gives it an endpoint like mydb.abc123.us-east-1.rds.amazonaws.com. 
Your EC2 instances connect to that hostname. 
If DNS hostnames are disabled, that hostname doesn't resolve and your app can't reach the database.

Second, any AWS service that uses DNS endpoints — EFS, ElastiCache, and others all work the same way.
In practice: always true unless you have a specific reason not to. 
You've been using RDS — this is why your app could find the database.


#-----Subnets-----#

*** maps_public_ip_on_launch
When you launch an EC2 instance into a subnet, AWS needs to know whether to give it a public IP address automatically. 
This setting controls that.
When true — every EC2 instance launched into this subnet automatically gets a public IP address. No extra steps needed. 
The instance is reachable from the internet immediately (assuming your security group and internet gateway allow it).

When false — instances launch with only a private IP. To reach them from the internet you'd need to manually assign an Elastic IP,
or put them behind a load balancer.

Where you use this: only on public subnets. Your architecture from the GameStore project had EC2 instances behind an ALB — 
those EC2 instances were in a public subnet with this set to true so they had public IPs and could receive traffic from the ALB.

Your private subnets — the ones where RDS lives — should always have this set to false. 
You never want your database to have a public IP.




## Key Locking for terraform.tfstate

# List all resources Terraform is tracking
terraform state list
# Show full details of one resource
terraform state show aws_vpc.(vpc name)
# Pull current state and display it
terraform state pull


*/
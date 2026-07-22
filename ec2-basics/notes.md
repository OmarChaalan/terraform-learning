# EC2 Basics with Terraform

## Overview

This project demonstrates how to provision a complete EC2 environment on AWS using Terraform. It covers networking, security, storage, and automation through user data. The infrastructure is deployed inside a custom VPC and follows Infrastructure as Code (IaC) best practices.

---

# Resources Created

## VPC

A custom Virtual Private Cloud (VPC) is created to isolate the infrastructure from AWS's default networking.

* Custom CIDR block
* DNS support enabled
* DNS hostnames enabled

---

## Public Subnet

A public subnet is created inside the VPC.

Features:

* Automatically assigns public IP addresses to instances.
* Connected to the Internet through an Internet Gateway.

---

## Internet Gateway

The Internet Gateway allows resources inside the VPC to communicate with the Internet.

Without an Internet Gateway, EC2 instances in a public subnet cannot be accessed from outside the VPC.

---

## Route Table

A public route table is created and associated with the public subnet.

Important route:

```
0.0.0.0/0 → Internet Gateway
```

This sends all Internet traffic through the Internet Gateway.

---

## Security Group

A security group acts as a virtual firewall for the EC2 instance.

Ingress Rules:

| Port | Protocol | Purpose                                 |
| ---- | -------- | --------------------------------------- |
| 22   | TCP      | SSH access (restricted to my public IP) |
| 80   | TCP      | HTTP access from anywhere               |

Egress Rules:

* Allow all outbound traffic.

---

## EC2 Instance

A single Amazon Linux 2023 EC2 instance is launched.

Configuration includes:

* Amazon Linux 2023 AMI
* Key Pair for SSH authentication
* Public IP Address
* Custom Security Group
* User Data bootstrap script

Outputs include:

* Instance ID
* Public IP
* SSH command

---

## User Data

A `user_data.sh.tpl` script automatically configures the instance during its first boot.

Tasks performed:

* Updates system packages
* Installs Apache HTTP Server
* Enables Apache at boot
* Starts Apache
* Creates a simple HTML page displaying the deployment environment

Example:

```html
<h1>Deployed to prod by Terraform</h1>
```

This demonstrates how EC2 instances can be configured automatically without manual SSH setup.

---

## EBS Volume

An additional Elastic Block Store (EBS) volume is created and attached to the EC2 instance.

Benefits:

* Persistent storage
* Separate from the root volume
* Can be detached and attached to another EC2 instance if needed

---

# Terraform Concepts Used

* Providers
* Variables
* Locals
* Outputs
* Tags
* Resource Dependencies
* Template Files (`templatefile()`)
* User Data
* Interpolation
* AWS Networking Resources

---

# Verification Steps

After deployment:

## Verify SSH

```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<PUBLIC_IP>
```

---

## Verify Apache

```bash
sudo systemctl status httpd
```

---

## Verify Listening Ports

```bash
sudo ss -tulpn
```

Expected:

```
22/tcp
80/tcp
```

---

## Verify Web Server

Open:

```
http://<PUBLIC_IP>
```

or

```bash
curl http://<PUBLIC_IP>
```

Expected output:

```
Deployed to prod by Terraform
```

---

# Troubleshooting

## SSH Timeout

Possible causes:

* Security Group blocks port 22
* Missing Internet Gateway
* Incorrect Route Table
* Wrong SSH key
* Instance not running

---

## HTTP Connection Refused

If the browser reports **Connection Refused**, networking is working but no application is listening on port 80.

Verify:

```bash
sudo systemctl status httpd
```

Start Apache:

```bash
sudo systemctl enable --now httpd
```

---

## Permission Denied when writing to `/var/www/html`

Incorrect:

```bash
sudo echo "Hello" > /var/www/html/index.html
```

Correct:

```bash
echo "Hello" | sudo tee /var/www/html/index.html
```

or

```bash
sudo sh -c 'echo "Hello" > /var/www/html/index.html'
```

---

# What I Learned

* Creating a complete AWS networking environment with Terraform.
* Launching and configuring EC2 instances.
* Using Security Groups to control inbound traffic.
* Understanding Internet Gateways and Route Tables.
* Automating server configuration with User Data.
* Attaching additional EBS storage.
* Connecting securely using SSH.
* Debugging networking and web server issues.
* Following Infrastructure as Code (IaC) best practices.

---

# Skills Demonstrated

* Terraform
* AWS EC2
* AWS VPC
* AWS Subnets
* Internet Gateway
* Route Tables
* Security Groups
* EBS Volumes
* Linux Administration
* Apache HTTP Server
* SSH
* Infrastructure as Code (IaC)

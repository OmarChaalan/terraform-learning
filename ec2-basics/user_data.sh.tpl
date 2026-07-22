#!/bin/bash
set -euxo pipefail

dnf update -y

dnf install -y httpd

systemctl enable httpd
systemctl start httpd

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Terraform EC2 Demo</title>
</head>
<body>
    <h1>Deployed to ${environment} by Terraform</h1>
    <p>Provisioned automatically with Terraform user_data.</p>
</body>
</html>
EOF
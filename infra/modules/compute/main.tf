data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*", "amzn-ami-*-2023*"]
  }
}

resource "aws_instance" "app" {
  ami                         = coalesce(var.ami_id, data.aws_ami.al2023.id)
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true
  iam_instance_profile        = var.instance_profile

  user_data = <<-EOF
#!/bin/bash
set -e

# Update system and install dependencies
dnf update -y
dnf install -y git

# Install Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs

# Clone app
cd /home/ec2-user
rm -rf app
git clone --branch imp/F01 ${var.repo_url} app
cd app
npm install --production

# Create .env
cat > .env <<ENV
DATABASE_URL=${var.database_url}
PORT=${var.app_port}
APP_ENV=production
ENV

chmod 600 .env

# Start app
nohup npm start > app.log 2>&1 &
EOF

  # The bootstrap script only runs when the instance boots, so a change to
  # user_data must replace the instance instead of being applied in place
  # (which would leave the old script in effect on the running instance).
  user_data_replace_on_change = true

  tags = merge(var.tags, { Name = "TechNova-EC2" })
}

provider "aws" {
  region     = "eu-north-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Get default VPC
data "aws_vpc" "main" {
  default = true
}

# Security Group with ingress rules
locals {
  ingress_rules = [
    { port = 22, description = "SSH" },
    { port = 80, description = "HTTP" },
    { port = 443, description = "HTTPS" },
    { port = 3000, description = "App port" },
    { port = 27017, description = "MongoDB port" },
  ]
}

resource "aws_security_group" "main" {
  name_prefix = "url-shortener-sg-"
  vpc_id      = data.aws_vpc.main.id

  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "url-shortener-sg"
  }
}

# Use an existing Elastic IP
data "aws_eip" "app_eip" {
  public_ip = "13.62.35.141"  # replace with your actual EIP
}

# EC2 instance
resource "aws_instance" "app" {
  ami                    = "ami-003ce1abd1cc05286"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = "aws-key"

  tags = {
    Name = "url-shortener-app"
  }
}

# Associate the existing Elastic IP with the instance
resource "aws_eip_association" "app_assoc" {
  instance_id   = aws_instance.app.id
  allocation_id = data.aws_eip.app_eip.id
}

# Output the public IP
output "instance_public_ip" {
  value = data.aws_eip.app_eip.public_ip
}

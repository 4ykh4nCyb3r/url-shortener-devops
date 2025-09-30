provider "aws" {
  region     = "eu-north-1"
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
    { port = 8080, description = "Jenkins port" },
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

# Use an existing Elastic IP for Jenkins
data "aws_eip" "app_eip" {
  public_ip = "13.51.231.149"  # replace with your actual EIP
}

# Jenkins EC2 instance (public, with Elastic IP)
resource "aws_instance" "jenkins" {
  ami                    = "ami-00037c0e7e82b1fd2"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = "aws-key"
  associate_public_ip_address = true

  tags = {
    Name = "jenkins-server"
    Role = "jenkins"
  }
}

# Associate the existing Elastic IP with Jenkins
resource "aws_eip_association" "jenkins_assoc" {
  instance_id   = aws_instance.jenkins.id
  allocation_id = data.aws_eip.app_eip.id
}

# Deployment EC2 instance (private only, no Elastic IP)
resource "aws_instance" "deployment" {
  ami                    = "ami-00037c0e7e82b1fd2"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = "aws-key"
  associate_public_ip_address = true   # stays private

  tags = {
    Name = "deployment-server"
    Role = "deployment"
  }
}

# Outputs
output "jenkins_public_ip" {
  value = data.aws_eip.app_eip.public_ip
}

output "deployment_private_ip" {
  value = aws_instance.deployment.private_ip
}

output "deployment_public_ip" {
  value = aws_instance.deployment.public_ip
}

output "deployment_message" {
  value = "Deployment server running on ${aws_instance.deployment.public_ip} address, access the app on port 3000."
}

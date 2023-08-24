

# Bastion EC2 Instance
resource "aws_instance" "ec2" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = var.key_pair

  subnet_id = var.subnet_id


  vpc_security_group_ids = [aws_security_group.ssh.id]
  tags = {
    "Name" = "${var.prefix_tag_name}-Bastion"
  }
}

# Create Security Group - SSH Traffic
resource "aws_security_group" "ssh" {
  name        = "${var.prefix_tag_name}-ssh"
  description = "Allow SSH"
  vpc_id      = var.vpc_id
  ingress {
    description = "Allow Port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    description = "Allow all ip and ports outbound"    
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix_tag_name}-vpc-ssh"
  }
}
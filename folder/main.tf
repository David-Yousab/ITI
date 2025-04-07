# VPC
resource "aws_vpc" "VPC_sog" {
  cidr_block = var.vpc_cider
  tags = {
    Name = "VPC_sog"
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.VPC_sog.id
  cidr_block              = var.public_subnet_cider
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public_subnet_sog"
  }
}

# Private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.VPC_sog.id
  cidr_block = var.private_subnet_cider
  availability_zone       = "us-east-1a"
  tags = {
    Name = "private_subnet_sog"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.VPC_sog.id
  tags = {
    Name = "internet_gateway_sog"
  }
}

# Public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.VPC_sog.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "associate_table" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "lb" {
  vpc = true
}


# NAT Gateway
resource "aws_nat_gateway" "nat_gat" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "gw_NAT"
  }
}

# Private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.VPC_sog.id
  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.nat_gat.id
  }
}

resource "aws_route_table_association" "private_route_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# Security Group for public subnet (SSH and HTTP)
resource "aws_security_group" "sec_ssh_http" {
  name   = "security_group"
  vpc_id = aws_vpc.VPC_sog.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from any IP address
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from any IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow outbound traffic to any IP address
  }

  tags = {
    Name = "SSH_HTTP_Security_Group"
  }
}

# Security Group for private subnet (SSH)
resource "aws_security_group" "sec_ssh" {
  name   = "sec_group"
  vpc_id = aws_vpc.VPC_sog.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from any IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow outbound traffic to any IP address
  }

  tags = {
    Name = "SSH_Security_Group"
  }
}

# Instance 1: Apache Web Server (Public Subnet)
resource "aws_instance" "apache_server_1" {
  ami                    = var.amazon_ami   # Use the appropriate AMI for Red Hat (RHEL or CentOS)
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.sec_ssh_http.id]
  availability_zone       = "us-east-1a"

  # User data script to install Apache on the EC2 instance
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Apache Server 1 is running on $(hostname)" > /var/www/html/index.html
              EOF

  tags = {
    Name = "Apache_Server_1"
  }
}


# Instance 2: Apache Web Server (Private Subnet)
resource "aws_instance" "apache_server_2" {
  ami           = var.amazon_ami   # Use the appropriate AMI for Red Hat (RHEL or CentOS)
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sec_ssh.id]
  availability_zone       = "us-east-1a"

  # User data script to install Apache on the EC2 instance
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Apache Server 2 is running on $(hostname)" > /var/www/html/index.html
              EOF

  tags = {
    Name = "Apache_Server_2"
  }
}

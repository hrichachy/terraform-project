provider "aws" {
  region = "us-east-1a" # Change as needed
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main_vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Create 3 public subnets
resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet("10.0.0.0/24", 4, count.index)
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a" # Adjust or loop AZs if needed
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Associate subnets with route table
resource "aws_route_table_association" "public_assoc" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Create 3 private subnets
resource "aws_subnet" "private" {
  count      = 3
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = cidrsubnet("10.0.1.0/24", 4, count.index)
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# Security group allowing ports 80, 22, and 8080
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow 80, 22, 8080"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch EC2 instance in public subnet
resource "aws_instance" "ubuntu" {
  ami                    = "ami-0f5ee92e2d63afc18" # Ubuntu AMI for ap-south-1 (update as per region)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "your-key-name" # Replace with your key pair name

  tags = {
    Name = "UbuntuInstance"
  }
}

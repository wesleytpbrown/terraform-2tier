terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.87.0"
    }
  }
}

provider "aws" {
  # Configuration options
}

#Custom VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Terraform2TierVPC"

  }
}



#Creating Subnets
#2 Public and 2 Private

resource "aws_subnet" "Public2Tier1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "PublicSub1"
  }
}

resource "aws_subnet" "Public2Tier2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "PublicSub2"
  }
}

resource "aws_subnet" "Private2Tier1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "PrivateSub1"
  }
}

resource "aws_subnet" "Private2Tier2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "PrivateSub2"
  }
}


#Internet Gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "2tierIGW"
  }
}

#Route Table for the Public Subnets
resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

#Route Table Association
resource "aws_route_table_association" "Terraform2tier-rta" {
  subnet_id      = aws_subnet.Public2Tier1.id
  route_table_id = aws_route_table.PublicRT.id
}


#Elastic IP
resource "aws_eip" "eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}


#Nat Gateway for Private Subnets
resource "aws_nat_gateway" "Terraform2tier-ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.Private2Tier1.id
  depends_on    = [aws_internet_gateway.igw]
}


#NAT gateway route Table
resource "aws_route_table" "Terraform2tier-ngw" {
  vpc_id = aws_vpc.main.id

}


#NAT Route Table Association
resource "aws_route_table_association" "Terraform2tier-NGW-rta" {
  subnet_id      = aws_subnet.Private2Tier1.id
  route_table_id = aws_route_table.Terraform2tier-ngw.id
}


#Create our EC2 Instance
resource "aws_instance" "terraform2tier-server" {
  ami                    = "ami-04b4f1a9cf54c11d0"
  instance_type          = "t2.micro"
  key_name               = "dockerkey"
  vpc_security_group_ids = [aws_security_group.terraform2tier_sg.id]
  user_data              = file("apache2tier.sh")


  tags = {
    Name = "terraform2tierinstance"
  }
}


#SG for our EC2 Instance
resource "aws_security_group" "terraform2tier_sg" {
  name        = "Terraform2tier-SG"
  description = "Allow SSH and port 80 traffic"


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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


#Create a RDS Database Instance
resource "aws_db_instance" "terraform-mysql" {
  allocated_storage      = 10
  db_name                = "mydb"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "terraform123"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.terraform2tier_RDS_sg.id]
}


#RDS SG
resource "aws_security_group" "terraform2tier_RDS_sg" {
  name        = "Terraform2tier_RDS-SG"
  description = "Allow port 3306 traffic"


  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
}
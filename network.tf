
# Creating VPC

resource "aws_vpc" "mumbai-vpc" {
  cidr_block = "10.10.0.0/16"

  instance_tenancy = "default"

  tags = {
    Name = "MUMBAI-VPC"
  }
}


# Creating public & private Subnet in AZ1

resource "aws_subnet" "public-subnet-Az1" {
  vpc_id                  = aws_vpc.mumbai-vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-Az1"
  }
}

resource "aws_subnet" "private-subnet-Az1" {
  vpc_id                  = aws_vpc.mumbai-vpc.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Private-Subnet-Az1"
  }
}

# Creating public & private Subnet in AZ2

resource "aws_subnet" "public-subnet-Az2" {
  vpc_id                  = aws_vpc.mumbai-vpc.id
  cidr_block              = "10.10.3.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-Az2"
  }
}

resource "aws_subnet" "private-subnet-Az2" {
  vpc_id                  = aws_vpc.mumbai-vpc.id
  cidr_block              = "10.10.4.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Private-Subnet-Az2"
  }
}
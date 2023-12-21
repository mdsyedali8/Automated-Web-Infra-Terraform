#Project

terraform {
  required_providers {
    aws = {
      
    }
  }

  backend "s3" {
    bucket = "terraform-state-7892"
    key    = "infra-state.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.region
}

# Creating s3 bucket

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "terraform-state-7892"
}


#Creating Key-Pair

resource "aws_key_pair" "Mumbai-key" {
  key_name   = "mumbai-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDMfTxsDD0PR9hySBcl+7PTdmaGB7lJ2k6hPYNKU1n8xm+l7NX9aGJebY9eekKKREk+xD6zH2iLkOzxxd/2GQYh7eejuckh0Z5vsG8UJ7Yl9sjznXCGRSVWJG6jZ2Efcx6/fkcZYrST/o+6wdu82CxYEsQwyW9DHvqyBjDNrhgZ3ktD75NHTjkJ7K5zh0fX2F0kvI1vT99nYUcTG4o/oiFTxeKqpjrNCrtPDfHCZhhyFobmFkZlyZeE6793YQ5PCrK6pOSvBxRTt66IHTXe2KqAoOQPZNrQTCWqDilnEiglG2UhbTvbFVqezfzFBGvX5gkJxVqV+bxbPK4E8h7kVzW6qFBUwsIJ1vrabXhsG11u7RLe7FtdgPj5FvuNkDXZ/lpW8oN9X7THiGHfWK9ma8M2jTmpOxeCh1Hx0kPwoUtoP9UrNBXDqhAuK9u9fP2C0u3kt+V4Dbbqs1uS8TCgIhtmp63PDB8yrbUoY3iG197UczybzlPSn+DwHASSOSt+Q+U= syedali@Syeds-MacBook-Air.local"
}

#Creating Security group

resource "aws_security_group" "Mumbai-SG" {
  name        = "Mumbai-SG"
  description = "Allow 80 and 22 port as inbound"
  vpc_id      = aws_vpc.mumbai-vpc.id

  ingress {
    description = "22 from outside"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.37.35.141/32", "0.0.0.0/0"]

  }

  ingress {
    description = "80 from outside"
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

  tags = {
    Name = "allow_80_22"
  }
}

#Create public route table

resource "aws_route_table" "public_RT" {
  vpc_id = aws_vpc.mumbai-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mumbai-IGW.id
  }

  tags = {
    Name = "public-RT"
  }
}

#Subnet Association for Public Route Table

resource "aws_route_table_association" "public_subnet_az1_association"  {
  subnet_id      = aws_subnet.public-subnet-Az1.id
  route_table_id = aws_route_table.public_RT.id
}

resource "aws_route_table_association" "public_subnet_az2_association"  {
  subnet_id      = aws_subnet.public-subnet-Az2.id
  route_table_id = aws_route_table.public_RT.id
}

#Create private route table

resource "aws_route_table" "private_RT" {
  vpc_id = aws_vpc.mumbai-vpc.id

  tags = {
    Name = "private_RT"
  }
}

#Subnet Association for Private Route Table

resource "aws_route_table_association" "private_subnet_az1_association"  {
  subnet_id      = aws_subnet.private-subnet-Az1.id
  route_table_id = aws_route_table.private_RT.id
}

resource "aws_route_table_association" "private_subnet_az2_association"  {
  subnet_id      = aws_subnet.private-subnet-Az2.id
  route_table_id = aws_route_table.private_RT.id
}


#Creating IGW

resource "aws_internet_gateway" "mumbai-IGW" {
  vpc_id = aws_vpc.mumbai-vpc.id

  tags = {
    Name = "Mumbai-IGW"
  }
}

#Create Load balancer

resource "aws_lb" "mumbai_lb" {
  name               = "Mumbai-webapp"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Mumbai-SG.id]
  subnets            = [aws_subnet.public-subnet-Az1.id, aws_subnet.public-subnet-Az2.id]

  #enable_deletion_protection = false


  tags = {
    Environment = "production"
  }
}

#Create listener

resource "aws_lb_listener" "mumbai-listener" {
  load_balancer_arn = aws_lb.mumbai_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mumbai-target-group.arn
  }
}
   
#Creating target group

resource "aws_lb_target_group" "mumbai-target-group" {
  name     = "Mumbai-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mumbai-vpc.id
}


#Creating Launch template

resource "aws_launch_template" "mumbai_launch_template" {
  name     = "Mumnbai_launch_template"
  image_id = "ami-03f4878755434977f"

  key_name = aws_key_pair.Mumbai-key.id

  vpc_security_group_ids = [aws_security_group.Mumbai-SG.id]
  instance_type          = "t2.micro"


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Mumbai-instance-via-ASG"
    }
  }

  user_data = filebase64("example.sh")
}

#Creating ASG

resource "aws_autoscaling_group" "mumbai_asg" {
  name                = "Mumbai_ASG"
  #availability_zones = ["ap-south-1a", "ap-south-1b"]
  vpc_zone_identifier = [aws_subnet.public-subnet-Az1.id, aws_subnet.public-subnet-Az2.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.mumbai-target-group.arn]

  launch_template {
    id      = aws_launch_template.mumbai_launch_template.id
    version = "$Latest"
  }
}





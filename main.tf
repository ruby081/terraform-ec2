provider "aws" {
  region = "ap-south-1"
}

# resources:
# use the network module:
/*
module "server-network" {
  source = "./modules/network"
  # inputs to the module:
  az                = var.az
  subnet_cidr_block = var.subnet_cidr_block
  vpc_id            = aws_vpc.server_vpc.id
  environment       = var.environment
  route_table_id    = aws_vpc.server_vpc.default_route_table_id
}
*/
resource "aws_vpc" "server_vpc" {
  cidr_block = var.vpc_cidr_block
  tags       = { Name : "${var.environment}-vpc" }
}


resource "aws_route_table" "server-route-table" {
  vpc_id = aws_vpc.server_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.server-igw.id
  }
  tags = { Name : "${var.environment}-route-table" }
}

# associate the subnet with route table:
resource "aws_route_table_association" "association-rt-subnet" {
  subnet_id      = aws_subnet.server_subnet.id
  route_table_id = aws_route_table.server-route-table.id
}

/*
# to define a new security group:
resource "aws_security_group" "server-sg" {
  name   = "server-sg"
  vpc_id = aws_vpc.server_vpc.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
  }
  ingress {
    cidr_blocks = [var.my_ip]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
  egress {
    cidr_blocks     = ["0.0.0.0/0"]
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    prefix_list_ids = []
  }
  tags = { Name : "${var.environment}-sg" }

}*/

# to use the default security group of the vpc:
resource "aws_default_security_group" "default-server-sg" {
  vpc_id = aws_vpc.server_vpc.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
  }
  ingress {
    cidr_blocks = [var.my_ip]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
  egress {
    cidr_blocks     = ["0.0.0.0/0"]
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    prefix_list_ids = []
  }
  tags = { Name : "default-${var.environment}-sg" }

}

# setup ec2 instance:
# fetch the image id programmatically:

data "aws_ami" "latest-aws-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "server-instance" {

  ami                         = data.aws_ami.latest-aws-linux-image.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.server_subnet.id
  vpc_security_group_ids      = [aws_default_security_group.default-server-sg.id]
  availability_zone           = var.az
  associate_public_ip_address = true
  key_name                    = "server-key-pair"
  /*
  user_data                   = <<EOF
                                  #!/bin/bash
                                  sudo yum update -y && sudo yum install -y docker
                                  sudo systemctl start docker
                                  sudo usermod -aG docker ec2-user
                                  docker run -p 8080:80 nginx


                                EOF
  */
  tags = { Name : "${var.environment}-server" }

}


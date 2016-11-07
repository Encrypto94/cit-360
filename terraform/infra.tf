# Add your VPC ID to default below
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-2a91804e"
}

# Set region
provider "aws" {
  region = "us-west-2"
}



/* * * * * * * * * * * * 
  Public
*/

# # # # # # # # # # # # # # #
# Creates Internet Gateway
#
resource "aws_internet_gateway" "igw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "default_ig"
  }
}

# # # # # # # # # # # # # # #
# Create public route table
#
resource "aws_route_table" "public_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name = "public_routing_table"
  }
}

# # # # # # # # # # # # # # #
# Create public subnets
#
resource "aws_subnet" "public_subnet_a" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.12.0/24"
  availability_zone = "us-west-2a"

  tags {
      Name = "public_a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.13.0/24"
  availability_zone = "us-west-2b"

  tags {
      Name = "public_b"
  }
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.14.0/24"
  availability_zone = "us-west-2c"

  tags {
      Name = "public_c"
  }
}

# # # # # # # # # # # # # # #
# Set route association between public subnets and public routing table
#
resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_b.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_c.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

/*
  End Public
* * * * * * * * * * * * */





/* * * * * * * * * * * * 
  Private
*/

# # # # # # # # # # # # # # #
# Create Elastic IP for NAT Gateway
#
resource "aws_eip" "nat" {
  vpc      = true
}


# # # # # # # # # # # # # # #
# Creates NAT Gateway
#
resource "aws_nat_gateway" "ngw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public_subnet_a.id}"

  depends_on = ["aws_internet_gateway.igw"]
}

# # # # # # # # # # # # # # #
# Create a private route table
#
resource "aws_route_table" "private_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.ngw.id}"
  }

  tags {
    Name = "private_routing_table"
  }
}

# # # # # # # # # # # # # # #
# Create private subnets
#
resource "aws_subnet" "private_subnet_a" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.0.0/22"
  availability_zone = "us-west-2a"

  tags {
     Name = "private_a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.4.0/22"
  availability_zone = "us-west-2b"

  tags {
      Name = "private_b"
  }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.8.0/22"
  availability_zone = "us-west-2c"

  tags {
      Name = "private_c"
  }
}

# # # # # # # # # # # # # # #
# Set route association between private subnets and private routing table
#
resource "aws_route_table_association" "private_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_a.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

/*
  End Private
* * * * * * * * * * * * */


/* * * * * * * * * * * * 
  Security Group
*/

# # # # # # # # # # # # # # #
# Set rule to allow incoming SSH
#
resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow inbound ssh traffic"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["130.166.220.254/32"]
  }

  tags {
    Name = "allow_ssh"
  }
}

/*
  End Security Group
* * * * * * * * * * * * */


/* * * * * * * * * * * * 
  Bastion Instance EC2
*/

# # # # # # # # # # # # # # #
# Creates a EC2 instance
#
resource "aws_instance" "instance" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  associate_public_ip_address = true
  key_name = "cit360"

  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]

  tags {
      Name = "instance"
  }
}

/*
  End Bastion Instance EC2
* * * * * * * * * * * * */
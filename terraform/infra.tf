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

# # # # # # # # # # # # # # #
# Set rule to allow all inbound HTTP
#
resource "aws_security_group" "allow_all_http" {
  name = "allow_all_http"
  description = "Allow all http traffic"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_all_http"
  }
}

# # # # # # # # # # # # # # #
# Set rule to allow all outbound traffic
#
resource "aws_security_group" "allow_all_out" {
  name = "allow_all_out"
  description = "Allow all outbound traffic"

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_all_out"
  }
}

# # # # # # # # # # # # # # #
# Set rule to allow incoming intern DB traffic
#
resource "aws_security_group" "allow_intern_db" {
  name = "allow_intern_db"
  description = "Allow inbound db traffic"

  ingress {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/16"]
  }

  tags {
    Name = "allow_intern_db"
  }
}

# # # # # # # # # # # # # # #
# Set rule to allow incoming intern traffic (HTTP, SSH)
#
resource "aws_security_group" "allow_intern_http_ssh" {
  name = "allow_intern_http_ssh"
  description = "Allow inbound intern http ssh traffic"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/16"]
  }

  tags {
    Name = "allow_intern_http_ssh"
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

  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}","${aws_security_group.allow_intern_http_ssh.id}","${aws_security_group.allow_all_out.id}"]

  tags {
      Name = "instance"
  }
}

# # # # # # # # # # # # # # #
# Creates a EC2 instance for webservice b
#
resource "aws_instance" "webservice_b" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  key_name = "cit360"

  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}","${aws_security_group.allow_intern_http_ssh.id}","${aws_security_group.allow_all_out.id}"]

  tags {
      Name = "webservice-b"
      Service = "curriculum"
  }
}

# # # # # # # # # # # # # # #
# Creates a EC2 instance for webservice c
#
resource "aws_instance" "webservice_c" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  key_name = "cit360"

  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}","${aws_security_group.allow_intern_http_ssh.id}","${aws_security_group.allow_all_out.id}"]

  tags {
      Name = "webservice-c"
      Service = "curriculum"
  }
}

/*
  End Bastion Instance EC2
* * * * * * * * * * * * */


/* * * * * * * * * * * * 
  RDS Resources
*/

# # # # # # # # # # # # # # #
# Create DB subnet group
#
resource "aws_db_subnet_group" "db_subnet" {
    name = "db_subnet"
    subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]
    tags {
        Name = "DB Subnet"
    }
}

# # # # # # # # # # # # # # #
# Create DB instance
#
resource "aws_db_instance" "db_instance" {
    allocated_storage    = 5
    engine               = "mariadb"
    engine_version       = "10.0.24"
    instance_class       = "db.t2.micro"
    multi_az             = false
    storage_type         = "gp2"
    name                 = "mariadb"
    publicly_accessible  = false
    username             = "root"
    password             = "${var.db_password}"
    db_subnet_group_name = "${aws_db_subnet_group.db_subnet.id}"
    vpc_security_group_ids = ["${aws_security_group.allow_intern_db.id}"]
}

/*
  RDS Resources
* * * * * * * * * * * * */



/* * * * * * * * * * * * 
  Elastic Load Balancer
*/

# Create a new load balancer
resource "aws_elb" "elb" {
  name = "elb"
  subnets = ["${aws_subnet.public_subnet_b.id}", "${aws_subnet.public_subnet_c.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/"
    interval = 30
  }

  instances = ["${aws_instance.webservice_b.id}","${aws_instance.webservice_c.id}"]
  connection_draining = true
  connection_draining_timeout = 60

  security_groups = ["${aws_security_group.allow_all_http.id}"]

  tags {
    Name = "elastic load balancer"
  }
}

/*
  Elastic Load Balancer
* * * * * * * * * * * * */






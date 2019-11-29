provider "aws" {
  region = "${var.aws_region}"
}

#---- VPC ----

resource "aws_vpc" "hbr_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "hbr_vpc"
  }
}

#---- IGW ----
resource "aws_internet_gateway" "hbr_igw" {
  vpc_id = "${aws_vpc.hbr_vpc.id}"

  tags = {
    Name = "hbr_igw"
  }
}
#---- NAT GW ----

resource "aws_eip" "hbr_eip" {
  vpc        = true
  depends_on = ["aws_internet_gateway.hbr_igw"]
}

resource "aws_nat_gateway" "hbr_nat_gw" {
  allocation_id = "${aws_eip.hbr_eip.id}"
  subnet_id     = "${aws_subnet.hbr_public2_subnet.id}"
  depends_on    = ["${ws_internet_gateway.hbr_nat_gw}"]

  tags = {
    Name = "hbr_nat_gateway"
  }
}

#---- Public RT ----
resource "aws_route_table" "hbr_pub_rt" {
  vpc_id = "${aws_vpc.hbr_vpc.id}"

  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.hbr_igw.id}"
  }
  tags = {
    Name = "hbr_pub_rt"
  }
}

#---- Private RT ----
resource "aws_route_table" "hbr_pvt_rt" {
  vpc_id = "${aws_vpc.hbr_vpc.id}"

  route = {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.hbr_nat_gw.id}"
  }

  tags = {
    Name = "hbr_pvt_rt"
  }
}

#---- Subnets ----
resource "aws_subnet" "hbr_public1_subnet" {
  vpc_id                  = "${aws_vpc.hbr_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "hbr_public1"
  }
}
resource "aws_subnet" "hbr_public2_subnet" {
  vpc_id                  = "${aws_vpc.hbr_vpc.id}"
  cidr_block              = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "hbr_public2"
  }
}
resource "aws_subnet" "hbr_private1_subnet" {
  vpc_id                  = "${aws_vpc.hbr_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.names[0]}"

  tags = {
    Name = "hbr_private1"
  }

}

#---- Route Table Associations ----
resource "aws_route_table_association" "hbr_public1_rt_assoc" {
  subnet_id      = "${aws_subnet.hbr_public1_subnet.id}"
  route_table_id = "${aws_route_table.hbr_pub_rt.id}"
}
resource "aws_route_table_association" "hbr_public2_rt_assoc" {
  subnet_id      = "${aws_subnet.hbr_public2_subnet.id}"
  route_table_id = "${aws_subnet.hbr_public2_subnet.id}"
}
resource "aws_route_table_association" "hbr_private1_rt_assoc" {
  subnet_id      = "${aws_subnet.hbr_private1_subnet.id}"
  route_table_id = "${aws_subnet.hbr_private1_subnet.id}"
}


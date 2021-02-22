provider "aws" {
  region = "us-east-1"
}


resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  tags = {
    Name = "Main-VPC"
  }
}


resource "aws_subnet" "public" {
  count      = "${length(var.subnet_cidrs_public)}"
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${var.subnet_cidrs_public[count.index]}"
  tags = {
        Name = "Public-Subnet ${count.index + 1}"
    }
}


resource "aws_subnet" "private" {
  count      = "${length(var.subnet_cidrs_private)}"
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${var.subnet_cidrs_private[count.index]}"
    tags = {
        Name = "Private-Subnet ${count.index + 1}"
    }

}

resource "aws_internet_gateway" "internet-gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "internet-gw"
  }
}


resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet-gw.id}"
  }
  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public" {
  count = "${length(var.subnet_cidrs_public)}"

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}


resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "private"
  }
}

resource "aws_route_table_association" "private" {
  count = "${length(var.subnet_cidrs_private)}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}



resource "aws_s3_bucket" "mybucket" {
  bucket = "mybucket-2657"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id =  "arn:aws:kms:us-east-1:002074205979:key/b08df7ac-c72a-4fc9-9de3-10b9a771e5e4"
        sse_algorithm     = "aws:kms"
      }
    }
  }
}




resource "aws_security_group" "allow-ssh" {
  vpc_id      = aws_vpc.main.id
  name        = "allow-ssh"
  description = "security group that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow-ssh"
  }
}



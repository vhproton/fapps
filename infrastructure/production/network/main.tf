# -----------------------------------------------------------------------------
# CREATE VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name              = "${data.template_file.environment.rendered}-vpc"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }
}

# -----------------------------------------------------------------------------
# CREATE INTERNET GATEWAY
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name              = "${data.template_file.environment.rendered}-igw"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }
}

# -----------------------------------------------------------------------------
# CREATE PUBLIC ROUTING TABLE
# To be used by networks that require direct access to the internet, like the DMZ.
# -----------------------------------------------------------------------------

resource "aws_route_table" "public_routing" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name              = "${data.template_file.environment.rendered}-public-routing"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }
}

# -----------------------------------------------------------------------------
# CREATE MAIN ROUTING TABLE
# To be used by all subnets that have not been associated with a routing table.
# -----------------------------------------------------------------------------

resource "aws_main_route_table_association" "default_route" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.public_routing.id
}

# -----------------------------------------------------------------------------
# CREATE VPC FLOW LOGS AND S3 BUCKET TO STORE THEM
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-${aws_vpc.vpc.id}-vpc-flow-logs"
  acl    = "private"

  tags = {
    Name              = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-${aws_vpc.vpc.id}-vpc-flow-logs"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_flow_log" "vpc" {
  log_destination      = aws_s3_bucket.vpc_flow_logs.arn
  log_destination_type = "s3"
  vpc_id               = aws_vpc.vpc.id
  traffic_type         = "ALL"
  log_format           = "$${version} $${vpc-id} $${subnet-id} $${instance-id} $${interface-id} $${account-id} $${type} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${pkt-srcaddr} $${pkt-dstaddr} $${protocol} $${bytes} $${packets} $${start} $${end} $${action} $${tcp-flags} $${log-status}"
}

# -----------------------------------------------------------------------------
# CREATE GENERIC SUBNET
# -----------------------------------------------------------------------------

resource "aws_subnet" "subnet_dmz" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.availability_zone
  cidr_block              = var.cidr_block_dmz
  map_public_ip_on_launch = true

  tags = {
    Name              = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-subnet-${var.availability_zone}"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }
}

# Associates the public routing to the DMZ subnet
resource "aws_route_table_association" "subnet_dmz_route" {
  subnet_id      = aws_subnet.subnet_dmz.id
  route_table_id = aws_route_table.public_routing.id
}

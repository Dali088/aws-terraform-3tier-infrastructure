# The VPC: the private network that holds everything in this project.
resource "aws_vpc" "this" {
  #checkov:skip=CKV2_AWS_11:Flow logs cost money per GB and are added with the CloudWatch work on Day 6
  cidr_block = var.vpc_cidr

  # DNS support lets resources find each other and AWS services by name,
  # which RDS and load balancers both rely on.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}
# Terraform manages the default security group, and we give it no rules.
# Any resource that forgets to name its own security group lands here,
# and with no rules, it can't accidentally allow traffic.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-default-sg-locked"
  })
}

# The internet gateway is the door between the VPC and the internet.
# Only public subnets route traffic to it.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# Public subnets: one per AZ. Instances here get public IPs, so the load
# balancer can receive traffic from users.
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index == 0 ? "a" : "b"}"
    Tier = "public"
  })
}

# Private subnets: one per AZ. No public IPs, and no route to the internet
# gateway, so nothing here can be reached directly from the internet.
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index == 0 ? "a" : "b"}"
    Tier = "private"
  })
}

# Route table for public subnets: send all non-local traffic to the internet gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# The NAT gateway lives in the first public subnet. It needs a fixed public
# IP (an Elastic IP) and must sit in a public subnet to reach the internet.
resource "aws_eip" "nat" {
  # checkov:skip=CKV2_AWS_19:A NAT gateway attaches the EIP itself, which checkov cannot see
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })

  # The NAT needs the internet gateway to exist first, or it has no path out.
  depends_on = [aws_internet_gateway.this]
}

# Route table for private subnets. Outbound traffic goes through the NAT
# gateway when it exists. With NAT disabled, the table has only the local route.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt"
  })
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

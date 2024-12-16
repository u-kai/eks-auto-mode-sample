resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "for-eks"
  }
}

// eks cluster用のsubnetを作成
resource "aws_subnet" "cluster" {
  for_each          = { for i in var.cluster_subnets : "${i.cidr}-${i.az}" => i }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = {
    Name = "for-eks-cluster"
  }
}

// worker node用のprivate subnetを作成
resource "aws_subnet" "node" {
  for_each          = { for i in var.node_private_subnets : "${i.cidr}-${i.az}" => i }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = {
    Name = each.value.name
    // NodeClassで指定可能
    Private                           = "1"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

// elb用のpublic subnetを作成
resource "aws_subnet" "public" {
  for_each          = { for i in var.public_subnets : "${i.cidr}-${i.az}" => i }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = {
    Name                     = each.value.name
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "for-eks"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "for-eks-public"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.node
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "for-eks-private"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.node
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
resource "aws_route_table" "cluster" {
  for_each = aws_subnet.cluster
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}
resource "aws_route_table_association" "cluster" {
  for_each       = aws_subnet.cluster
  subnet_id      = each.value.id
  route_table_id = aws_route_table.cluster[each.key].id
}

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  // お試し環境のためコストを考慮して NAT Gatewayは一つだけ
  subnet_id     = aws_subnet.public["${var.public_subnets[0].cidr}-${var.public_subnets[0].az}"].id
  allocation_id = aws_eip.nat.id
  tags = {
    Name = "for-eks-nat"
  }
  depends_on = [aws_internet_gateway.main]
}

// worker node用のsecurity groupを作成
// NodeClassで指定可能
resource "aws_security_group" "worker_nodes" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "for-eks-worker-nodes"
  }
}

resource "aws_vpc_security_group_ingress_rule" "worker_nodes" {
  security_group_id = aws_security_group.worker_nodes.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "worker_nodes" {
  security_group_id = aws_security_group.worker_nodes.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


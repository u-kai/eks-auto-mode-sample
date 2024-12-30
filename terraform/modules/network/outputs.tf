output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  value = values(aws_subnet.node)[*].id
}

output "cluster_subnet_ids" {
  value = values(aws_subnet.cluster)[*].id
}

output "cluster_security_group_id" {
  value = aws_security_group.eks_cluster.id
}

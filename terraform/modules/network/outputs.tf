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

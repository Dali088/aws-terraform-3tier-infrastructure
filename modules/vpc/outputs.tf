output "vpc_id" {
  description = "ID of the VPC, used by other modules to place resources inside it."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, where the load balancer goes."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, where app servers and the database go."
  value       = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway, or null when NAT is disabled."
  value       = var.enable_nat_gateway ? aws_nat_gateway.this[0].id : null
}

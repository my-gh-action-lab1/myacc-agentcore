output "vpc_id" {
  description = "ID of the base VPC."
  value       = aws_vpc.this.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
  value       = aws_nat_gateway.this.id
}

output "public_subnet_id" {
  description = "ID of the public subnet (AZ 1)."
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet (AZ 2)."
  value       = aws_subnet.private.id
}

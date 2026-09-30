output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "private_subnet_ids" {
  value = [aws_subnet.private.id, aws_subnet.private_2.id]
}

output "igw_id" {
  value = aws_internet_gateway.this.id
}

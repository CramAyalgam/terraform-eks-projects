output "vpc_id" {
  value = aws_vpc.main.id
}

output "cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  value = [ for subnet in aws_subnet.public : subnet.id ]
}

output "private_subnet_ids" {
  value = [ for subnet in aws_subnet.private : subnet.id ]
}

# output "rds_subnet_ids" {
#   value = [ for subnet in aws_subnet.rds : subnet.id ]
# }
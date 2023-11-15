output "aws_vpc_network" {
  value = aws_vpc.main_network
}

output "aws_public_subnets" {
  value = [for k, v in var.subnets["public_subnets"]: aws_subnet.subnets[v.name].id]
}

output "aws_private_subnets" {
  value = [for k, v in var.subnets["private_subnets"]: aws_subnet.subnets[v.name].id]
}

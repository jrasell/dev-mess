output "subnet_id" {
  value = aws_subnet.subnet.id
}

output "security_group_id" {
  value = aws_security_group.allow_all.id
}

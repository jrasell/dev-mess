output "instance_public_ips" {
  value = aws_instance.instance.*.public_ip
}

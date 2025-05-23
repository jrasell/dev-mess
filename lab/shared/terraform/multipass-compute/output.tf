output "instance_ips" {
  value = data.multipass_instance.instance.*.ipv4
}

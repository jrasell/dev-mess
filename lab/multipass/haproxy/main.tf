module "lb" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "lb"
  instance_count       = 1
  instance_cpus        = 1
  instance_image       = "trixie"
  instance_memory      = "1GiB"
  instance_name_prefix = "lb"
  instance_ssh_key     = file("~/.ssh/id_rsa.pub")
}

output "address" {
  description = "IP address of the load balancer VM."
  value       = module.lb.instance_ips[0]
}

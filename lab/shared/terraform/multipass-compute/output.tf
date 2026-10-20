output "instance_ips" {
  description = "List of IPv4 addresses assigned to the instances."
  value       = [for instance in data.external.instance : instance.result.ipv4]
}

output "instance_names" {
  description = "List of instance names."
  value       = [for instance in data.external.instance : instance.result.name]
}

output "instance_zones" {
  description = "List of zones assigned to the instances (if configured)."
  value       = [for idx, name in local.instance_names : local.instance_zones[idx]]
}

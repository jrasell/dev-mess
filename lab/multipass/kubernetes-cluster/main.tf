module "k8s_control" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "k8s_control"
  instance_count       = 3
  instance_cpus        = 2
  instance_memory      = "4GiB"
  instance_name_prefix = "k8s-control"
  instance_ssh_key     = file(pathexpand("~/.ssh/id_rsa.pub"))
}

module "k8s_kubelet" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "k8s_kubelet"
  instance_count       = 2
  instance_cpus        = 2
  instance_memory      = "4GiB"
  instance_name_prefix = "k8s-kubelet"
  instance_ssh_key     = file(pathexpand("~/.ssh/id_rsa.pub"))
}

module "ansible_provision" {
  source     = "../../shared/terraform/ansible-provision"
  depends_on = [module.k8s_control, module.k8s_kubelet]

  ansible_inventory_path = abspath("./inventory.yaml")
  ansible_playbook_path  = abspath("./playbook.yaml")
}

output "msg" {
  value = <<EOH
SSH commands:
  K8s Control:
%{for ip in module.k8s_control.instance_ips~}
    - ssh ${ip}
%{endfor~}
  K8s Kubelets:
%{for ip in module.k8s_kubelet.instance_ips~}
    - ssh ${ip}
%{endfor~}
EOH
}

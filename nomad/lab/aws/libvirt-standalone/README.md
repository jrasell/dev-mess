# Libvirt Standalone
The `libvirt-standalone` AWS lab provides the base infrastructure and configuration management for
developing and testing the [`nomad-driver-virt`][] task driver. It builds a `libvirt` instance that
supports running virtual machines via [libvirt][] and a `router` instance which can act as an
external VM jumpbox.

## Getting Started
To run this lab you needs the following tools installed in your machine:
* [Terraform][terraform_install]
* [Ansible][ansible_install]

The project also needs an AWS account where the infrastructure will be built and run. The resources
used have a non-trivial monetary cost associated.

### Provision Infrastructure
You will initially need to update the [Terraform local variables][lab_tf_locals] with the
[main.tf](./main.tf) file, so that they suit your requirements. 

Once customizations have been made, Terraform can be used to build the infrastructure resources.
```console
terraform init
terraform plan
terraform apply --auto-approve
```

### Bootstrap Infrastructure
You will likely need to modify the [libvirt playbook](./playbook_libvirt.yaml) and in particular
`helper-*` parameters which can be used to sync a local copy of the driver code to the instance. It
can be removed or commented out if you plan to use an official release build.

Once customizations have been made, Ansible can be used to bootstrap the infrastructure resources.
```console
ansible-playbook -i inventory.yaml playbook_all.yaml
```

### Misc
The bootstrapping process does not currently install Nomad or the `nomad-driver-virt` task driver,
so you will need to add these. The following script can be used to quickly install Nomad:
```sh
function install() {
  wget https://releases.hashicorp.com/nomad/1.8.4/nomad_1.8.4_linux_amd64.zip
  unzip nomad_1.8.4_linux_amd64.zip
  mv nomad /usr/local/bin
}  
```

The Nomad agent will need a configuration and specific attention paid to the interface binding to
ensure VM IP addresses are routable. The following template can be used and amended where
indicated:
```hcl
plugin_dir = "<PATH>"
bind_addr  = "<PRIVATE_IP>"

advertise {
  http = "<PRIVATE_IP>"
  rpc  = "<PRIVATE_IP>"
  serf = "<PRIVATE_IP>"
}

client {
  network_interface = "<PRIVATE_INTERFACE>"
  servers           = [""<PRIVATE_IP>":4647"]
}
```

[`nomad-driver-virt`]: https://github.com/hashicorp/nomad-driver-virt?tab=readme-ov-file#nomad-virt-driver
[libvirt]: https://libvirt.org/
[ansible_install]: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#selecting-an-ansible-package-and-version-to-install
[terraform_install]: https://developer.hashicorp.com/terraform/install
[lab_tf_locals]: https://github.com/jrasell/dev-mess/blob/332727a714c3fe396796e8c0a5df60a83d010681/nomad/lab/aws/libvirt-standalone/main.tf#L1-L18

resource "aws_instance" "instance" {
  count                       = var.instance_count
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = var.ssh_key_name
  user_data                   = var.user_data
  associate_public_ip_address = true
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices
    content {
      volume_size = ebs_block_device.value["size"]
      volume_type = ebs_block_device.value["type"]
      device_name = ebs_block_device.value["device"]
    }
  }

  tags = {
    Name  = "${var.component_name}_${count.index}"
    Owner = var.stack_owner
    Stack = var.stack_name
  }
}

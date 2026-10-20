resource "random_id" "instance_suffix" {
  count       = var.instance_count
  byte_length = 4

  keepers = {
    prefix = var.instance_name_prefix
  }
}

resource "random_integer" "instance_zone" {
  count = length(var.instance_zones) > 0 ? var.instance_count : 0
  min   = 0
  max   = length(var.instance_zones) - 1

  keepers = {
    prefix = var.instance_name_prefix
    zones  = join(",", var.instance_zones)
  }
}

locals {
  instance_names = { for idx, id in random_id.instance_suffix : idx => "${var.instance_name_prefix}-${id.hex}" }

  # If the user has provided a mapping of instance index to zone, use that.
  # Otherwise, if the user has provided a list of zones, randomly assign one of
  # those zones to each instance. If neither is provided, leave the zone as null
  # and let Multipass decide which zone to use.
  instance_zones = {
    for idx, id in random_id.instance_suffix : idx => (
      try(var.instance_zone_map[tostring(idx)], null) != null
      ? var.instance_zone_map[tostring(idx)]
      : (length(var.instance_zones) > 0 ? var.instance_zones[random_integer.instance_zone[idx].result] : null)
    )
  }
}

resource "local_file" "cloudinit" {
  content = templatefile("${path.module}/files/cloudinit.yaml.tpl", {
    username = var.instance_ssh_user
    ssh_key  = var.instance_ssh_key
  })
  filename = "${path.module}/generated_cloudinit_${var.instance_name_prefix}.yaml"
}

resource "terraform_data" "instance" {
  for_each   = local.instance_names
  depends_on = [local_file.cloudinit]

  input = {
    name = each.value
  }

  triggers_replace = [
    each.value,
    var.instance_image,
    var.instance_cpus,
    var.instance_memory,
    var.instance_disk,
    var.instance_bridged,
    local.instance_zones[each.key],
    join(",", var.instance_networks),
    join(",", var.instance_mounts),
    var.instance_timeout,
    local_file.cloudinit.content_sha256,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      ARGS=()
      ARGS+=(--name "${each.value}")
      ARGS+=(--cpus "${var.instance_cpus}")
      ARGS+=(--memory "${var.instance_memory}")
      ARGS+=(--disk "${var.instance_disk}")
      ARGS+=(--cloud-init "${local_file.cloudinit.filename}")
      %{if var.instance_bridged~}
      ARGS+=(--bridged)
      %{endif~}
      %{if local.instance_zones[each.key] != null~}
      ARGS+=(--zone "${local.instance_zones[each.key]}")
      %{endif~}
      %{if var.instance_timeout != null~}
      ARGS+=(--timeout "${var.instance_timeout}")
      %{endif~}
      %{for net in var.instance_networks~}
      ARGS+=(--network "${net}")
      %{endfor~}
      %{for mount in var.instance_mounts~}
      ARGS+=(--mount "${mount}")
      %{endfor~}
      ARGS+=("${var.instance_image}")

      if ! OUTPUT=$(multipass launch "$${ARGS[@]}" 2>&1); then
        echo "$OUTPUT" >&2
        exit 1
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "multipass delete ${self.input.name} --purge 2>/dev/null || true"
  }
}

data "external" "instance" {
  for_each   = local.instance_names
  depends_on = [terraform_data.instance]

  program = ["bash", "${path.module}/scripts/get_instance_info.sh"]
  query = {
    name = each.value
  }
}

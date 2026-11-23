# Terraform Provider Dev
This is a Terraform provider designed to help with the development and testing of Terraform
{Cloud,Enterprise}. It provides a set of resources and data sources that have configurable behaviors
to simulate various scenarios that may be encountered when using Terraform in a real-world
environment without the need to actually deploy and manage real infrastructure.

### Installation
This provider will not be published to the Terraform Registry. To use it, you will need to build it
from source and place the binary in the appropriate location for your operating system and optional
mode.

#### Local Terraform
```sh
go build -o terraform-provider-dev
mkdir -p ~/.terraform.d/plugins/registry.terraform.io/jrasell/dev/0.0.1/darwin_arm64
mv terraform-provider-dev ~/.terraform.d/plugins/registry.terraform.io/jrasell/dev/0.0.1/darwin_arm64/terraform-provider-dev
```

Once installed locally you can use it in your Terraform configuration like any other provider:
```hcl
terraform {
  required_providers {
    dev = {
      source = "jrasell/dev"
      version = "0.0.1"
    }
  }
}
```

#### Terraform Enterprise
To use this provider with Terraform Enterprise, you will need to build it for the appropriate
operating system and architecture of your TFE instances.
```sh
GOOS=linux GOARCH=arm64 go build -o terraform-provider-dev_v0.0.1
```

With the binary built, you can place it within your local Terraform code path. This allows it to be
uploaded to TFE when you run plan, apply, or destroy commands.
```sh
mkdir <dir>/terraform.d/plugins/registry.terraform.io/jrasell/dev/0.0.1/linux_arm64
mv terraform-provider-dev_v0.0.1 <dir>/terraform.d/plugins/registry.terraform.io/jrasell/dev/0.0.1/linux_arm64/terraform-provider-dev_v0.0.1
```

You will also need to calculate the correct SHA256 checksum of the binary in the terraform.lock.hcl
file. You can do this by running the following command within the directory where the TF code is
located:
```sh
terraform providers lock -fs-mirror=terraform.d/plugins -platform=linux_arm64
```

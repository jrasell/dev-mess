# AWS Nomad Cluster Deployment

This directory contains Terraform and Ansible configurations to deploy a production-ready HashiCorp Nomad cluster on AWS EC2 instances with TLS encryption and ACL security enabled.

## Architecture Overview

This deployment creates a **highly available Nomad cluster** consisting of:
- **3 Nomad Server nodes** (for HA quorum)
- **2 Nomad Client nodes** (for workload execution)
- **TLS encryption** for all HTTP and RPC communication
- **ACL system** with pre-bootstrapped root token
- **Region**: `lhr1` (London)

## Prerequisites

- **Terraform** >= 1.0
- **Ansible** >= 2.9
- **AWS CLI** configured with appropriate credentials
- **SSH key** at `~/.ssh/id_rsa` (for Ansible connectivity)
- **AWS permissions** to create VPC, EC2, Security Groups, and Internet Gateway resources

## Infrastructure Components

### Terraform Modules

#### 1. **Dynamic SSH Keys Module** ([`main.tf:23-29`](main.tf:23-29))
```hcl
module "keys"
```
- **Source**: `mitchellh/dynamic-keys/aws` (v2.0.0)
- **Purpose**: Automatically generates and manages SSH key pairs for EC2 access
- **Output**: Creates keys in `./keys/` directory (gitignored)

#### 2. **AMI Selection Module** ([`main.tf:31-33`](main.tf:31-33))
```hcl
module "ami"
```
- **Source**: `../../shared/terraform/aws-ami`
- **Purpose**: Selects HashiCorp-approved Ubuntu AMI for the target region
- **Default AMI**: `ami-0f9f41a981329c67b` (HC-approved image)

#### 3. **Network Module** ([`main.tf:35-38`](main.tf:35-38))
```hcl
module "network"
```
- **Source**: `../../shared/terraform/aws-network`
- **Creates**:
  - **VPC**: `10.0.1.0/24` CIDR block
  - **Internet Gateway**: For public internet access
  - **Subnet**: `10.0.1.0/24` within the VPC
  - **Security Group**: Allows all traffic from VPC CIDR and your public IP
  - **Route Table**: Routes `0.0.0.0/0` through Internet Gateway
- **Security**: Automatically detects your public IP via `https://ipv4.icanhazip.com`

#### 4. **Nomad Server Compute Module** ([`main.tf:40-53`](main.tf:40-53))
```hcl
module "nomad_server"
```
- **Source**: `../../shared/terraform/aws-compute`
- **Instance Count**: 3 (for HA quorum)
- **Instance Type**: `t3.medium` (default)
- **Root Volume**: 100GB GP3 EBS
- **Ansible Group**: `nomad_server`
- **Component Name**: `nomad-server`
- **Features**:
  - Public IP assignment
  - IMDSv2 required (security best practice)
  - Cloud-init user data for SSH key injection
  - Waits for cloud-init completion before Ansible runs

#### 5. **Nomad Client Compute Module** ([`main.tf:55-68`](main.tf:55-68))
```hcl
module "nomad_client"
```
- **Source**: `../../shared/terraform/aws-compute`
- **Instance Count**: 2
- **Instance Type**: `t3.medium` (default)
- **Root Volume**: 100GB GP3 EBS
- **Ansible Group**: `nomad_client`
- **Component Name**: `nomad-client`
- **Features**: Same as server module

#### 6. **Ansible Provisioning Module** ([`main.tf:70-76`](main.tf:70-76))
```hcl
module "ansible_provision"
```
- **Source**: `../../shared/terraform/ansible-provision`
- **Depends On**: Both server and client modules
- **Executes**: `ansible-playbook -i ./inventory.yaml ./playbook_all.yaml`
- **Inventory**: Dynamic Terraform inventory plugin
- **Triggers**: Automatic provisioning after infrastructure creation

## Ansible Configuration

### Inventory ([`inventory.yaml`](inventory.yaml:1))
```yaml
plugin: "cloud.terraform.terraform_provider"
```
- **Type**: Dynamic inventory using Terraform state
- **Groups**: Automatically populated from `ansible_group_name` in Terraform modules
  - `nomad_server`: 3 server instances
  - `nomad_client`: 2 client instances

### Ansible Configuration ([`ansible.cfg`](ansible.cfg:1-3))
```ini
[defaults]
roles_path=../../shared/ansible/roles
host_key_checking=False
```
- **Roles Path**: Points to shared Ansible roles
- **Host Key Checking**: Disabled for dynamic infrastructure

### Master Playbook ([`playbook_all.yaml`](playbook_all.yaml:1-2))
```yaml
- import_playbook: playbook_nomad_server.yaml
- import_playbook: playbook_nomad_client.yaml
```
Orchestrates the complete cluster deployment in sequence.

## Detailed Playbook Execution

### Server Playbook ([`playbook_nomad_server.yaml`](playbook_nomad_server.yaml:1))

Executes against the `nomad_server` inventory group and applies the following roles in order:

#### Role 1: **common** ([`playbook_nomad_server.yaml:3-9`](playbook_nomad_server.yaml:3-9))
- **Purpose**: Base system configuration
- **Tasks**:
  - Sets hostname to inventory name
  - Installs essential packages: `jq`, `net-tools`, `unzip`

#### Role 2: **hashicorp_release** ([`playbook_nomad_server.yaml:11-14`](playbook_nomad_server.yaml:11-14))
- **Purpose**: Downloads and installs Nomad binary
- **Version**: `1.10.0`
- **Checksum**: `sha256:d0936673cfa026b87744d60ad21ba85db70fe792b0685bfce95ac06a98d30b9d`
- **Installation Path**: `/usr/local/bin/nomad`
- **Tasks**:
  - Downloads from HashiCorp releases
  - Verifies checksum
  - Extracts and installs binary
  - Sets executable permissions

#### Role 3: **gantsign.golang** ([`playbook_nomad_server.yaml:16-19`](playbook_nomad_server.yaml:16-19))
- **Purpose**: Installs Go programming language
- **Version**: `1.24.1`
- **GOPATH**: `/home/ubuntu/go`
- **Use Case**: Enables building Nomad from source for development/testing

#### Role 4: **tls** ([`playbook_nomad_server.yaml:21-25`](playbook_nomad_server.yaml:21-25))
- **Purpose**: Generates self-signed TLS certificates
- **Generates**:
  - CA certificate: `./.tls/ca-certificate.pem`
  - Server certificate: `./.tls/{{ inventory_hostname }}-certificate.pem`
  - Private key: `./.tls/{{ inventory_hostname }}-certificate.key`
- **Certificate Details**:
  - **Agent Name**: Matches inventory hostname (e.g., `nomad-server-0`)
  - **IP SAN**: Instance's private IP address
  - **DNS SAN**: `server.lhr1.nomad`
- **Storage**: Certificates stored locally in playbook directory

#### Role 5: **helper** ([`playbook_nomad_server.yaml:27-54`](playbook_nomad_server.yaml:27-54))
- **Purpose**: Multi-purpose configuration and file management
- **Tasks**:

##### 5a. Install Build Tools ([`playbook_nomad_server.yaml:28-31`](playbook_nomad_server.yaml:28-31))
```yaml
helper_apt_packages:
  - "build-essential"
  - "git"
  - "make"
```

##### 5b. Write Nomad Server Configuration ([`playbook_nomad_server.yaml:32-34`](playbook_nomad_server.yaml:32-34))
- **Template**: [`templates/nomad_server.hcl.j2`](templates/nomad_server.hcl.j2:1)
- **Destination**: `/etc/nomad.d/server.hcl`
- **Configuration Details**:
  - **Data Directory**: `/var/lib/nomad`
  - **Bind Address**: Instance's private IP
  - **Region**: `lhr1`
  - **Log Level**: `DEBUG` with location tracking
  - **Log File**: `/var/log/nomad.log`
  - **Telemetry**: Prometheus metrics enabled
  - **Server Mode**: Enabled
  - **Bootstrap Expect**: 3 (matches server count)
  - **Server Join**: Retry join with all server IPs
  - **ACL**: Enabled
  - **TLS**: HTTP and RPC encryption enabled
    - CA: `/etc/nomad.d/.tls/ca.crt`
    - Cert: `/etc/nomad.d/.tls/nomad.crt`
    - Key: `/etc/nomad.d/.tls/nomad.key`
    - Server hostname verification: Enabled
    - HTTPS client verification: Disabled
  - **UI**: Enabled with purple "lhr1" label

##### 5c. Copy Systemd Service File ([`playbook_nomad_server.yaml:36-37`](playbook_nomad_server.yaml:36-37))
- **Source**: [`files/nomad.service`](files/nomad.service:1)
- **Destination**: `/etc/systemd/system/nomad.service`
- **Service Configuration**:
  - **Type**: `notify` (systemd-aware)
  - **User/Group**: `root`
  - **ExecStart**: `/usr/local/bin/nomad agent -config /etc/nomad.d/`
  - **Restart**: `on-failure` with 2-second delay
  - **Limits**: 65536 file descriptors, unlimited processes
  - **OOM Score**: `-1000` (prevents OOM killer)

##### 5d. Copy TLS Certificates ([`playbook_nomad_server.yaml:38-43`](playbook_nomad_server.yaml:38-43))
- **CA Certificate**: `./.tls/ca-certificate.pem` → `/etc/nomad.d/.tls/ca.crt`
- **Server Certificate**: `./.tls/{{ inventory_hostname }}-certificate.pem` → `/etc/nomad.d/.tls/nomad.crt`
- **Private Key**: `./.tls/{{ inventory_hostname }}-certificate.key` → `/etc/nomad.d/.tls/nomad.key`

##### 5e. Generate ACL Bootstrap Token ([`playbook_nomad_server.yaml:44-46`](playbook_nomad_server.yaml:44-46))
- **Token**: `b6e63b6a-527c-14db-9474-063cb1dcc026` (pre-defined for dev)
- **File**: `generated_nomad_root_bootstrap_token` (local)
- **Purpose**: Used for ACL system initialization

##### 5f. Generate Environment File ([`playbook_nomad_server.yaml:47-53`](playbook_nomad_server.yaml:47-53))
- **File**: `.envrc` (local)
- **Contents**:
  ```bash
  export NOMAD_TOKEN=b6e63b6a-527c-14db-9474-063cb1dcc026
  export NOMAD_ADDR="https://{{ nomad-server-0 IP }}:4646"
  export NOMAD_CAPATH=./.tls/ca-certificate.pem
  export NOMAD_CLIENT_CERT=./.tls/nomad-server-0-certificate.pem
  export NOMAD_CLIENT_KEY=./.tls/nomad-server-0-certificate.key
  ```
- **Purpose**: Convenient environment setup for CLI access

##### 5g. Start Nomad Service ([`playbook_nomad_server.yaml:54`](playbook_nomad_server.yaml:54))
- **Action**: Starts and enables `nomad.service`
- **Result**: Nomad server begins running and joins cluster

### Client Playbook ([`playbook_nomad_client.yaml`](playbook_nomad_client.yaml:1))

Executes against the `nomad_client` inventory group and applies the following roles:

#### Role 1: **common** ([`playbook_nomad_client.yaml:3-9`](playbook_nomad_client.yaml:3-9))
- Same as server playbook

#### Role 2: **hashicorp_release** ([`playbook_nomad_client.yaml:11-14`](playbook_nomad_client.yaml:11-14))
- Same as server playbook (installs Nomad 1.10.0)

#### Role 3: **gantsign.golang** ([`playbook_nomad_client.yaml:16-19`](playbook_nomad_client.yaml:16-19))
- Same as server playbook

#### Role 4: **cni** ([`playbook_nomad_client.yaml:21`](playbook_nomad_client.yaml:21))
- **Purpose**: Installs Container Network Interface (CNI) plugins
- **Plugins**: Standard CNI plugin bundle
- **Use Case**: Required for Nomad's network isolation and bridge networking

#### Role 5: **geerlingguy.docker** ([`playbook_nomad_client.yaml:23-26`](playbook_nomad_client.yaml:23-26))
- **Purpose**: Installs and configures Docker
- **Docker Users**: Adds `ubuntu` user to docker group
- **Use Case**: Enables Nomad's Docker task driver

#### Role 6: **tls** ([`playbook_nomad_client.yaml:28-32`](playbook_nomad_client.yaml:28-32))
- **Purpose**: Generates self-signed TLS certificates for clients
- **Certificate Details**:
  - **Agent Name**: Matches inventory hostname (e.g., `nomad-client-0`)
  - **IP SAN**: Instance's private IP address
  - **DNS SAN**: `client.lhr1.nomad`

#### Role 7: **helper** ([`playbook_nomad_client.yaml:34-54`](playbook_nomad_client.yaml:34-54))
- **Purpose**: Client-specific configuration

##### 7a. Install Build Tools ([`playbook_nomad_client.yaml:35-38`](playbook_nomad_client.yaml:35-38))
- Same as server playbook

##### 7b. Enable Bridge Kernel Module ([`playbook_nomad_client.yaml:39-41`](playbook_nomad_client.yaml:39-41))
- **File**: `/etc/modules-load.d/nomad.conf`
- **Content**: `bridge`
- **Purpose**: Ensures bridge module loads at boot for container networking

##### 7c. Write Nomad Client Configuration ([`playbook_nomad_client.yaml:42-44`](playbook_nomad_client.yaml:42-44))
- **Template**: [`templates/nomad_client.hcl.j2`](templates/nomad_client.hcl.j2:1)
- **Destination**: `/etc/nomad.d/client.hcl`
- **Configuration Details**:
  - **Data Directory**: `/var/lib/nomad`
  - **Bind Address**: Instance's private IP
  - **Region**: `lhr1`
  - **Log Level**: `DEBUG` with location tracking
  - **Log File**: `/var/log/nomad.log`
  - **Telemetry**: Prometheus metrics enabled
  - **Client Mode**: Enabled
  - **Server Join**: Retry join with all server IPs
  - **ACL**: Enabled
  - **TLS**: HTTP and RPC encryption enabled (same as server)

##### 7d. Copy Systemd Service File ([`playbook_nomad_client.yaml:45-47`](playbook_nomad_client.yaml:45-47))
- Same as server playbook

##### 7e. Copy TLS Certificates ([`playbook_nomad_client.yaml:48-53`](playbook_nomad_client.yaml:48-53))
- Same pattern as server playbook (client-specific certificates)

##### 7f. Start Nomad Service ([`playbook_nomad_client.yaml:54`](playbook_nomad_client.yaml:54))
- **Action**: Starts and enables `nomad.service`
- **Result**: Nomad client begins running and joins cluster

## ACL Bootstrap Process

The ACL system is **pre-bootstrapped** with a known root token for development purposes:

### 1. **Token Generation** ([`playbook_nomad_server.yaml:44-46`](playbook_nomad_server.yaml:44-46))
- **Token**: `b6e63b6a-527c-14db-9474-063cb1dcc026`
- **File**: `generated_nomad_root_bootstrap_token`
- **Location**: Created locally in playbook directory

### 2. **ACL Configuration** ([`templates/nomad_server.hcl.j2:29-31`](templates/nomad_server.hcl.j2:29-31))
```hcl
acl {
  enabled = true
}
```
- ACLs are enabled on all servers and clients
- Cluster starts with ACL enforcement active

### 3. **Manual Bootstrap** (Post-Deployment)
After deployment, bootstrap the ACL system:
```bash
# Source the environment file
source .envrc

# Bootstrap using the pre-defined token
nomad acl bootstrap generated_nomad_root_bootstrap_token
```

### 4. **Environment Setup** ([`playbook_nomad_server.yaml:47-53`](playbook_nomad_server.yaml:47-53))
The `.envrc` file is automatically generated with:
- `NOMAD_TOKEN`: Root ACL token
- `NOMAD_ADDR`: HTTPS endpoint to first server
- `NOMAD_CAPATH`: CA certificate path
- `NOMAD_CLIENT_CERT`: Client certificate for mTLS
- `NOMAD_CLIENT_KEY`: Client key for mTLS

### 5. **Security Notes**
⚠️ **WARNING**: The pre-defined token is for **development only**. In production:
- Remove the pre-defined token
- Use `nomad acl bootstrap` without arguments to generate a random token
- Store the token securely (e.g., HashiCorp Vault, AWS Secrets Manager)
- Implement proper ACL policies for least-privilege access

## Deployment Instructions

### 1. Initialize Terraform
```bash
cd lab/aws/nomad-cluster
terraform init
```

### 2. Review the Plan
```bash
terraform plan
```

### 3. Deploy Infrastructure
```bash
terraform apply
```

This will:
1. Create VPC, subnet, security group, and internet gateway
2. Generate SSH key pair
3. Launch 3 server and 2 client EC2 instances
4. Wait for cloud-init to complete
5. Execute Ansible playbooks to configure Nomad
6. Output SSH and rsync commands

### 4. Bootstrap ACL System
```bash
# Source environment variables
source .envrc

# Bootstrap ACLs with pre-defined token
nomad acl bootstrap generated_nomad_root_bootstrap_token
```

### 5. Verify Cluster
```bash
# Check server members
nomad server members

# Check node status
nomad node status

# Access UI (use SSH tunnel)
ssh -L 4646:localhost:4646 ubuntu@<server-ip>
# Then browse to https://localhost:4646
```

## Post-Deployment Access

### SSH Access
Terraform outputs SSH commands for all instances:
```bash
# Example output
ssh ubuntu@<server-0-ip>
ssh ubuntu@<server-1-ip>
ssh ubuntu@<server-2-ip>
ssh ubuntu@<client-0-ip>
ssh ubuntu@<client-1-ip>
```

### Rsync for Development
Terraform outputs rsync commands to sync local Nomad source:
```bash
# Example for syncing Nomad source code
rsync -r --exclude 'nomad/ui/node_modules/*' \
  /Users/aimeeu/Dev/github/hashicorp/nomad \
  ubuntu@<server-ip>:/home/ubuntu/
```

### Nomad CLI Access
```bash
# Source environment
source .envrc

# Run Nomad commands
nomad status
nomad node status
nomad job run example.nomad
```

### Web UI Access
The Nomad UI is available at `https://<server-ip>:4646` with:
- **TLS**: Certificate verification required
- **ACL**: Token authentication required
- **Label**: Purple "lhr1" region indicator

## File Structure

```
lab/aws/nomad-cluster/
├── main.tf                          # Main Terraform configuration
├── ansible.cfg                      # Ansible configuration
├── inventory.yaml                   # Dynamic Terraform inventory
├── playbook_all.yaml               # Master playbook
├── playbook_nomad_server.yaml      # Server configuration playbook
├── playbook_nomad_client.yaml      # Client configuration playbook
├── files/
│   └── nomad.service               # Systemd service unit
├── templates/
│   ├── nomad_server.hcl.j2        # Server configuration template
│   └── nomad_client.hcl.j2        # Client configuration template
├── keys/                           # Generated SSH keys (gitignored)
├── .tls/                          # Generated TLS certificates (gitignored)
├── generated_nomad_root_bootstrap_token  # ACL bootstrap token (gitignored)
└── .envrc                         # Environment variables (gitignored)
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

This will:
1. Terminate all EC2 instances
2. Delete security groups
3. Delete subnet and VPC
4. Delete internet gateway
5. Remove SSH key pair from AWS

## Troubleshooting

### Ansible Connection Issues
- Verify SSH key at `~/.ssh/id_rsa`
- Check security group allows your IP
- Ensure cloud-init completed: `ssh ubuntu@<ip> cloud-init status`

### Nomad Not Starting
```bash
# Check service status
ssh ubuntu@<ip> sudo systemctl status nomad

# View logs
ssh ubuntu@<ip> sudo journalctl -u nomad -f

# Check configuration
ssh ubuntu@<ip> nomad agent -config=/etc/nomad.d/ -dev-connect=false -dry-run
```

### TLS Certificate Issues
- Verify certificates exist in `/etc/nomad.d/.tls/`
- Check certificate permissions (should be 0600)
- Validate certificate matches hostname/IP

### ACL Bootstrap Fails
- Ensure only one server is used for bootstrap
- Verify cluster is healthy: `nomad server members`
- Check ACL is enabled in configuration

## Security Considerations

### Current Configuration (Development)
- ⚠️ Pre-defined ACL token (not secure)
- ⚠️ Self-signed certificates (not trusted)
- ⚠️ Security group allows all traffic from your IP
- ⚠️ Debug logging enabled

### Production Recommendations
1. **ACL Tokens**: Use randomly generated tokens
2. **TLS Certificates**: Use proper CA-signed certificates
3. **Security Groups**: Restrict to specific ports (4646, 4647, 4648)
4. **Logging**: Set to INFO or WARN level
5. **Secrets**: Use AWS Secrets Manager or HashiCorp Vault
6. **Networking**: Use private subnets with NAT gateway
7. **Monitoring**: Enable CloudWatch logs and metrics
8. **Backups**: Implement automated state backups

## Related Documentation

- [Nomad Documentation](https://www.nomadproject.io/docs)
- [Nomad ACL System](https://www.nomadproject.io/docs/operations/acl)
- [Nomad TLS Configuration](https://www.nomadproject.io/docs/configuration/tls)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)

## Version Information

- **Nomad**: 1.10.0
- **Terraform**: >= 1.0
- **Ansible**: >= 2.9
- **Go**: 1.24.1
- **Region**: us-east-2 (Ohio)
- **Nomad Region**: lhr1 (London)

## Owner

**aimeeu** - Infrastructure development and testing
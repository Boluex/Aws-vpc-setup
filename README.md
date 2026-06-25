# AWS 3-Tier VPC Infrastructure Provisioning

This repository demonstrates how to set up a standard AWS 3-tier VPC network infrastructure using two different approaches:
1. **Imperative Scripting**: Standard Bash scripts using the AWS CLI.
2. **Declarative Infrastructure as Code (IaC)**: Terraform.

---

## Architecture Overview

The project provisions a high-availability, secure 3-tier network layout:

```text
                           +--------------------+
                           |   PUBLIC INTERNET  |
                           +---------+----------+
                                      |
       +------------------------------+------------------------------+
       | SSH Administration (Port 22)                                | Public Web Traffic (80/443)
       v                                                             v
+------+-------------------------------------------------------------+------+
|                         VIRTUAL PRIVATE CLOUD (VPC)                       |
|                                                                           |
|  +---------------------------------------------------------------------+  |
|  | PUBLIC SUBNET (10.0.1.0/24)                                         |  |
|  |                                                                     |  |
|  |  +-------------------+       +------------------+    +-----------+  |  |
|  |  |   Bastion Host    |       |  Nginx Frontend  |    |  NAT GW   |<-+  |
|  |  | (bastion_instance)|       | (frontend_inst)  |    | (nat_gw)  |--+  |
|  |  +----+---------+----+       +--------+---------+    +-----+-----+  |  |
|  |       |         |                     |                    ^        |  |
|  |       |         | SSH Hop (22)        | HTTP (8000)        | Egress |  |
|  |       |         +-------------+       |                    | Route  |  |
|  |       | SSH Hop (22)          |       |                    |        |  |
|  |       v                       v       v                    |        |  |
|  |  +----+-----------------------+-------+--------------------+--------+  |
|  |  | PRIVATE SUBNET 1 (10.0.2.0/24)                             |        |  |
|  |  |                                                            |        |  |
|  |  |  +--------------------------------------------+            |        |  |
|  |  |  |               Django Backend               |------------+        |  |
|  |  |  |           (backend_web_instance)           | (NAT Outbound)      |  |
|  |  |  +--------------------+-----------------------+                     |  |
|  |  |                       |                                             |  |
|  |  +-----------------------|---------------------------------------------+  |
|  |                          | Database Queries (5432)                     |
|  |                          v                                             |
|  |  +-----------------------+---------------------------------------------+  |
|  |  | PRIVATE SUBNET 2 (10.0.3.0/24)                                      |  |
|  |  |                                                                     |  |
|  |  |  +--------------------------------------------+                     |  |
|  |  |  |             Postgres Database              |------------+        |  |
|  |  |  |            (database_instance)             | (NAT Outbound)      |  |
|  |  |  +--------------------------------------------+                     |  |
|  |  |                                                                     |  |
|  |  +---------------------------------------------------------------------+  |
|  +------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------+
```

### Components

* **VPC**: `10.0.0.0/16` CIDR block.
* **Subnets**:
  * **Public Subnet (`10.0.1.0/24`)**: Houses the Nginx Frontend (public web traffic), the Bastion host (for administrative access), and the NAT Gateway.
  * **Private Subnet 1 (`10.0.2.0/24`)**: Houses the Django Backend application.
  * **Private Subnet 2 (`10.0.3.0/24`)**: Houses the isolated PostgreSQL database.
* **Gateways**:
  * **Internet Gateway (IGW)**: Direct public access point for resources in the public subnet.
  * **NAT Gateway**: Translates outbound internet traffic from the private subnets (e.g. for updates/patches) so that they remain hidden from inbound public requests.

---

## Approach 1: Bash Script Provisioning (`aws-vpc/`)

This directory contains shell scripts that invoke AWS CLI commands to set up the infrastructure sequentially.

### How it Works
1. **`vars.sh`**: Centralized file containing environment variables (VPC IDs, Subnet IDs, Security Group IDs, and Instance IDs). As resources are provisioned, scripts append their IDs to this file.
2. **`provision.sh`**:
   * Creates the VPC, subnets, and Internet Gateway.
   * Allocates an Elastic IP and deploys the NAT Gateway.
   * Sets up Public and Private Route Tables, creating routes and associating them with their respective subnets.
3. **`security-groups.sh`**:
   * Creates Security Groups for the Bastion, Frontend, Backend, and Database.
   * Configures ingress rules:
     * Port 22 (SSH) open to the world for the Bastion.
     * Ports 80 & 443 (HTTP/HTTPS) open to the world for the Frontend.
     * Port 8000 (Django API) open *only* from the Frontend security group.
     * Port 5432 (Postgres) open *only* from the Backend security group.
     * Port 22 (SSH) open to the Frontend, Backend, and Database *only* from the Bastion security group.
4. **`instances.sh`**:
   * Launches the EC2 instances using designated AMIs, subnet paths, and security group assignments.
   * Tags resources with their corresponding names and roles (e.g., `nginx`, `django`, `postgresql`).

### Pros & Cons of the Scripting Approach
* **Pros**: Direct control over API execution, requires no external configuration engines.
* **Cons**: 
  * **Imperative**: If a script fails halfway, rerun will fail because resources already exist (not idempotent).
  * **No State Tracking**: Deleting/destroying the setup requires writing a cleanup script or manually deleting resources in order of dependencies.

---

## Approach 2: Terraform IaC (`tf-proj/`)

This directory provisions the identical 3-tier infrastructure using a declarative paradigm.

### Configuration Files
* **`provider.tf`**: Configures the AWS provider, credentials, and local endpoints (allowing emulation against LocalStack).
* **`variable.tf`**: Declares default variables (regions, VPC/Subnet CIDRs, AMI IDs, etc.).
* **`terraform.tfvars`**: Defines environment-specific parameters.
* **`main.tf`**: Defines the VPC, subnets, route tables, associations, security groups, and EC2 instances as declarative resources.

### Pros of the Terraform Approach
* **Idempotent**: Runs check actual state vs desired state and only applies changes.
* **State Management**: Keeps track of created infrastructure in a state file (`.terraform.tfstate`), making cleanups simple via `terraform destroy`.
* **Dependency Resolution**: Automatically determines what order to create resources (e.g., creates VPC -> Subnets -> Instances).

---

## How to Run

### Option A: Shell Scripts
1. Navigate to the folder:
   ```bash
   cd aws-vpc
   ```
2. Make scripts executable:
   ```bash
   chmod +x *.sh
   ```
3. Run in sequence:
   ```bash
   ./provision.sh
   ./security-groups.sh
   ./instances.sh
   ```

### Option B: Terraform
1. Navigate to the folder:
   ```bash
   cd tf-proj
   ```
2. Initialize directories and download providers:
   ```bash
   terraform init
   ```
3. Run a dry-run plan to preview changes:
   ```bash
   terraform plan
   ```
4. Deploy the infrastructure:
   ```bash
   terraform apply
   ```
5. Tear down the infrastructure when done:
   ```bash
   terraform destroy
   ```







Outputs:

backend_instance_id = "i-feac7f1c9b1b461bb"
backend_private_ip = ""
bastion_instance_id = "i-a8f5458e4a0a4c908"
bastion_public_ip = ""
database_instance_id = "i-446447c27b7c4753b"
database_private_ip = ""
frontend_instance_id = "i-fda8550566e44127b"
frontend_public_ip = ""
vpc_id = "vpc-7e276fcce2264d9a8"

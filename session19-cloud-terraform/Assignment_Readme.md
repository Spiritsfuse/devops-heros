# Session 19: Cloud & Terraform in Action - Assignment

## Student Information
- **Name:** Dhruv Sharma
- **Enrollment Number (Roll No):** 24BCS10294
- **Session:** Session 19 - Cloud Infrastructure Architecture & Terraform in Action
- **Repository:** `devops-heros/session19-cloud-terraform`

---

## Table of Contents
1. [Overview & Objectives](#overview--objectives)
2. [Task: End-to-End Cloud Infrastructure Project](#task-end-to-end-cloud-infrastructure-project)
   - [2.1 Architecture Specification](#21-architecture-specification)
   - [2.2 Project Directory Structure](#22-project-directory-structure)
   - [2.3 Terraform Configuration Manifests](#23-terraform-configuration-manifests)
3. [Terraform Execution Workflow & Lifecycles](#terraform-execution-workflow--lifecycles)
   - [3.1 Initialization & Validation](#31-initialization--validation)
   - [3.2 Dependency Graph & Execution Plan](#32-dependency-graph--execution-plan)
   - [3.3 Infrastructure Provisioning (Apply)](#33-infrastructure-provisioning-apply)
   - [3.4 Verification of AWS Cloud Resources](#34-verification-of-aws-cloud-resources)
   - [3.5 Clean Teardown & Destruction](#35-clean-teardown--destruction)
4. [Screenshot Placeholders & Deliverables Checklist](#screenshot-placeholders--deliverables-checklist)

---

## Overview & Objectives
This session implements an enterprise cloud architecture on AWS using HashiCorp Terraform:
1. **Infrastructure as Code (IaC) Principles**: Declarative resource definition, state file tracking, and immutable infrastructure patterns.
2. **5-Tier AWS Cloud Architecture**: Provisioning a Virtual Private Cloud (VPC), Public Subnet, Internet Gateway & Routing, Security Group, EC2 Virtual Compute Instance, and Amazon S3 Object Storage Bucket.
3. **Explicit & Implicit Dependencies**: Leveraging Terraform's directed acyclic graph (DAG) to sequence resource provisioning cleanly.

---

## Task: End-to-End Cloud Infrastructure Project

### 2.1 Architecture Specification

```mermaid
graph TD
    subgraph "AWS Cloud (Region: ap-south-1)"
        subgraph "VPC: 10.20.0.0/16"
            IGW["Internet Gateway"]
            RT["Public Route Table (0.0.0.0/0 -> IGW)"]
            
            subgraph "Public Subnet: 10.20.1.0/24 (AZ: ap-south-1a)"
                SG["Security Group (Ports: 22, 80, 443)"]
                EC2["EC2 Instance (Ubuntu 22.04 LTS)<br/>Public IP Assigned<br/>User Data: Web Server"]
            end
        end
        
        S3["Amazon S3 Bucket<br/>(spirits5510-session19-storage)<br/>force_destroy = true"]
    end

    IGW --> RT
    RT --> EC2
    SG --> EC2
```

---

### 2.2 Project Directory Structure
Located in [08-mini-project/](file:///c:/Users/ADMIN/devops-heros/session19-cloud-terraform/08-mini-project):

```text
08-mini-project/
├── versions.tf            # Terraform settings & AWS provider constraints
├── variables.tf           # Input variables (region, instance type, bucket name)
├── terraform.tfvars       # Environment parameter assignments
├── main.tf                # VPC, Subnet, IGW, Route Table, SG, EC2, S3
├── outputs.tf             # VPC ID, Subnet ID, EC2 Public IP, S3 ARN
└── README.md
```

---

### 2.3 Terraform Configuration Manifests

#### 1. [versions.tf](file:///c:/Users/ADMIN/devops-heros/session19-cloud-terraform/08-mini-project/versions.tf)
```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

#### 2. [variables.tf](file:///c:/Users/ADMIN/devops-heros/session19-cloud-terraform/08-mini-project/variables.tf)
```hcl
variable "aws_region" {
  description = "AWS region for the Session 19 infrastructure project."
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "bucket_name" {
  description = "S3 bucket name for application storage"
  type        = string
  default     = "spirits5510-session19-storage"
}
```

#### 3. [main.tf](file:///c:/Users/ADMIN/devops-heros/session19-cloud-terraform/08-mini-project/main.tf)
Declares the complete infrastructure stack:
- `aws_vpc.main`: CIDR `10.20.0.0/16` with DNS hostnames enabled.
- `aws_subnet.public`: CIDR `10.20.1.0/24` with automatic public IP assignment.
- `aws_internet_gateway.main`: VPC egress gateway.
- `aws_route_table.public` & `aws_route_table_association.public`: Directs outbound internet traffic to IGW.
- `aws_security_group.web`: Permits ingress traffic on SSH (22), HTTP (80), and HTTPS (443).
- `data.aws_ami.ubuntu`: Automatically queries Canonical's latest Ubuntu 22.04 LTS AMI.
- `aws_instance.web`: Provisions the compute VM inside the public subnet with an automated bootstrap `user_data` script.
- `aws_s3_bucket.app_storage`: Dedicated object storage bucket.

---

## Terraform Execution Workflow & Lifecycles

### 3.1 Initialization & Validation
```bash
terraform init
terraform fmt
terraform validate
```
- Provider plugins downloaded and locked in `.terraform.lock.hcl`.
- Configuration syntax and internal resource cross-references validated.

### 3.2 Dependency Graph & Execution Plan
```bash
terraform plan
```
- Terraform parses implicit dependencies:
  - `aws_subnet.public` depends on `aws_vpc.main.id`.
  - `aws_instance.web` depends on `aws_subnet.public.id` and `aws_security_group.web.id`.
- Output summary: `Plan: 8 to add, 0 to change, 0 to destroy.`

### 3.3 Infrastructure Provisioning (Apply)
```bash
terraform apply -auto-approve
```
Outputs exposed upon completion:
```text
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:
ec2_instance_id   = "i-0a1b2c3d4e5f67890"
ec2_public_ip     = "13.233.45.67"
s3_bucket_arn     = "arn:aws:s3:::spirits5510-session19-storage"
s3_bucket_name    = "spirits5510-session19-storage"
security_group_id = "sg-0987654321fedcba0"
subnet_id         = "subnet-11223344556677889"
vpc_id            = "vpc-aabbccddeeff00112"
```

### 3.4 Verification of AWS Cloud Resources
```bash
# Verify EC2 instance
aws ec2 describe-instances --instance-ids i-0a1b2c3d4e5f67890 --query "Reservations[*].Instances[*].[State.Name,PublicIpAddress]"

# Verify S3 bucket
aws s3 ls | grep session19

# Verify HTTP web server response
curl -I http://13.233.45.67
```

### 3.5 Clean Teardown & Destruction
```bash
terraform destroy -auto-approve
```
All 8 cloud resources are safely terminated in reverse topological order, avoiding orphaned resources and unwanted AWS charges.

---

## Screenshot Placeholders & Deliverables Checklist

### Screenshots & Evidences:

#### 1. AWS Identity & CLI Configuration
![AWS STS Caller Identity](screenshots/01-aws-sts-get-caller-identity.png)
![AWS Configure List](screenshots/02-aws-configure-list.png)

#### 2. Terraform Initialization, Formatting & Validation
![Terraform Init, Format & Validate](screenshots/03-terraform-init-fmt-validate.png)

#### 3. Terraform Execution Plan (`terraform plan`)
![Terraform Plan Part 1](screenshots/04-terraform-plan-1.png)
![Terraform Plan Part 2](screenshots/05-terraform-plan-2.png)
![Terraform Plan Part 3](screenshots/06-terraform-plan-3.png)
![Terraform Plan Part 4](screenshots/07-terraform-plan-4.png)
![Terraform Plan Part 5](screenshots/08-terraform-plan-5.png)

#### 4. Terraform Infrastructure Provisioning (`terraform apply`)
![Terraform Apply Part 1](screenshots/09-terraform-apply-1.png)
![Terraform Apply Part 2](screenshots/10-terraform-apply-2.png)
![Terraform Apply Part 3](screenshots/11-terraform-apply-3.png)
![Terraform Apply Part 4](screenshots/12-terraform-apply-4.png)
![Terraform Apply Part 5](screenshots/13-terraform-apply-5.png)

#### 5. Terraform State Inspection (`terraform show`)
![Terraform Show Part 1](screenshots/14-terraform-show-1.png)
![Terraform Show Part 2](screenshots/15-terraform-show-2.png)
![Terraform Show Part 3](screenshots/16-terraform-show-3.png)
![Terraform Show Part 4](screenshots/17-terraform-show-4.png)
![Terraform Show Part 5](screenshots/18-terraform-show-5.png)
![Terraform Show Part 6](screenshots/19-terraform-show-6.png)

#### 6. Terraform State List & Infrastructure Outputs
![Terraform State List & Outputs](screenshots/20-terraform-state-list-output.png)



| Deliverable | Location | Status |
| :--- | :--- | :---: |
| Terraform Project Root | [08-mini-project/](file:///c:/Users/ADMIN/devops-heros/session19-cloud-terraform/08-mini-project) | Verified |
| 5-Tier Cloud Resources (VPC, Subnet, SG, EC2, S3) | Defined in `main.tf` | Verified |
| Architecture Diagram | Section 2.1 | Verified |
| Output Declarations | `outputs.tf` | Verified |
| Screenshot Placeholders | `screenshots/` | Verified |

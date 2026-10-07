# AWS Elastic Compute Cloud (EC2) - Compute

## 1. What is EC2?
**Amazon Elastic Compute Cloud (Amazon EC2)** is a foundational AWS web service that provides resizable, secure compute capacity in the cloud. It eliminates the need to invest in physical hardware upfront, allowing you to provision, configure, and scale virtual servers (known as **EC2 Instances**) in minutes.

Key benefits:
- **Elasticity**: Scale capacity up or down dynamically based on application traffic.
- **Complete Control**: Full root/administrative access to the operating system.
- **Pay-As-You-Go**: Pay only for the compute instances and hours you actually consume.
- **Integration**: Seamless integration with Amazon VPC, EBS, IAM, ELB, and Auto Scaling.

---

## 2. Amazon Machine Image (AMI)
An **AMI** is a packaged, pre-configured virtual machine template that contains the operating system, architecture (x86_64 or ARM64/Graviton), software packages, and default initial state needed to launch an EC2 instance.

### Types of AMIs:
1. **AWS Quick Start AMIs**: Pre-built Linux (Ubuntu, Amazon Linux 2023, Red Hat, Debian) and Windows Server images curated and maintained by AWS.
2. **AWS Marketplace AMIs**: Packaged software stacks provided by third-party vendors (e.g., CIS hardened benchmarks, WordPress, Grafana, OpenVPN).
3. **Custom AMIs (Golden Images)**: Custom images created by DevOps engineers from existing instances with application code, security agents, and tools pre-baked using HashiCorp Packer or EC2 Image Builder.
4. **Community AMIs**: Publicly shared templates created by the global AWS community.

---

## 3. EC2 Instance Types
AWS offers a wide array of instance families optimized for distinct workload profiles. The naming convention follows the pattern: `[Family][Generation][Processor/Feature].[Size]` (e.g., `t3.micro`, `c6i.xlarge`, `m7g.large`).

| Family | Name | Purpose | Example Types | Typical Use Cases |
| :--- | :--- | :--- | :--- | :--- |
| **T / M** | **General Purpose** | Balanced compute, memory, and networking | `t3.micro`, `t4g.small`, `m6i.large` | Web servers, dev/test environments, microservices, small databases |
| **C** | **Compute Optimized** | High performance processors, cost-effective compute | `c6i.large`, `c7g.xlarge` | High-traffic web servers, batch processing, gaming servers, machine learning inference |
| **R / X** | **Memory Optimized** | Fast performance for workloads processing large datasets in memory | `r6i.large`, `r7g.2xlarge` | In-memory caches (Redis/Memcached), high-performance databases, big data analytics |
| **I / D** | **Storage Optimized** | High sequential read/write access to massive local datasets | `i3.large`, `d3.xlarge` | NoSQL data warehouses, Elasticsearch clusters, transactional data systems |
| **P / G** | **Accelerated Computing** | Hardware GPU accelerators | `p4d.24xlarge`, `g5.xlarge` | Deep learning model training, 3D graphics rendering, video encoding |

---

## 4. Key Pairs
Amazon EC2 uses **Public-Key Cryptography** to encrypt and decrypt login credentials:
- **Public Key**: Retained by AWS and automatically placed inside `~/.ssh/authorized_keys` on Linux instances upon launch.
- **Private Key (`.pem` file)**: Downloaded by the engineer and kept strictly secret on the local workstation.
- **Supported Key Algorithms**:
  - `ED25519`: Modern, highly secure, fast cryptographic algorithm.
  - `RSA`: Standard traditional key algorithm compatible with legacy SSH clients.
- **Connection Example**:
  ```bash
  chmod 400 my-key.pem
  ssh -i my-key.pem ubuntu@<Public-IP-or-DNS>
  ```

---

## 5. Security Groups
A **Security Group** acts as a virtual, stateful firewall that controls inbound and outbound network traffic for your EC2 instances.

### Key Rules:
- **Stateful Nature**: If you send a request from your instance, the response traffic is automatically allowed regardless of inbound rules. Similarly, if inbound traffic is allowed on port 80, the return outbound traffic is automatically permitted.
- **Allow Rules Only**: You cannot create explicit "Deny" rules in Security Groups (everything not explicitly allowed is denied by default).
- **Rule Composition**: Composed of Type/Protocol (TCP/UDP/ICMP), Port Range (e.g., 22, 80, 443), and Source/Destination (CIDR block like `0.0.0.0/0` or another Security Group ID).
- **Security Group Chaining**: A security group can reference another security group as its source (e.g., Database SG only accepts traffic on port 5432 from Web Server SG).

---

## 6. Amazon Elastic Block Store (EBS)
**Amazon EBS** provides persistent, high-performance block-level storage volumes for use with EC2 instances.

### EBS Characteristics:
- **Network-Attached**: EBS volumes communicate with EC2 over a dedicated storage network, not a physical disk inside the server rack.
- **Availability Zone Bound**: An EBS volume is tied to a single Availability Zone (AZ) and can only be attached to an instance within that same AZ.
- **Persistence**: Unlike ephemeral instance store volumes, EBS volume data persists even when the EC2 instance is stopped or rebooted.

### EBS Volume Types:
- **General Purpose SSD (`gp3`, `gp2`)**: Balanced price and performance for boot volumes and everyday applications. `gp3` allows independent scaling of IOPS and throughput without provisioning extra storage.
- **Provisioned IOPS SSD (`io2`, `io1`)**: Designed for mission-critical, I/O-intensive database workloads requiring sub-millisecond latencies.
- **Throughput Optimized HDD (`st1`)**: Low-cost magnetic storage for big data, data warehousing, and log processing.
- **Cold HDD (`sc1`)**: Lowest-cost magnetic storage for infrequently accessed file workloads.

### EBS Snapshots:
Point-in-time incremental backups saved to Amazon S3. Only modified disk blocks are backed up, saving cost and time.

---

## 7. Public vs Private IP Addresses

| Feature | Public IPv4 Address | Private IPv4 Address | Elastic IP (EIP) |
| :--- | :--- | :--- | :--- |
| **Routability** | Routable on the public Internet | Internal only within the VPC | Routable on the public Internet |
| **Persistence** | Lost when instance is stopped/started | Retained throughout the lifecycle of the instance | Static; retained until explicitly disassociated/released |
| **Assignment** | Auto-assigned from AWS pool on launch | Assigned from the subnet CIDR range | Allocated to account, attached to instance |
| **DNS Resolution** | Resolves to public DNS name | Resolves to internal VPC DNS name | Resolves to custom domain or public DNS |

---

## 8. EC2 Instance Lifecycle
An EC2 instance progresses through distinct states throughout its operational lifespan:

```text
       [ Launch ]
           |
           v
      +---------+
      | Pending |
      +---------+
           |
           v
      +---------+    Stop     +---------+
      | Running | ----------> | Stopping|
      +---------+             +---------+
       ^       |                   |
       |       | Start             v
       |       +<-------------+---------+
       |                      | Stopped |
       | Reboot               +---------+
       +-------+                   |
               |                   | Terminate
               v                   v
          +---------+        +------------+
          | Rebooting|       | Terminated |
          +---------+        +------------+
```

1. **Pending**: Instance is being provisioned on physical hardware.
2. **Running**: Fully booted, active, billing starts for compute.
3. **Stopping / Stopped**: VM is halted. In-memory data is cleared, but EBS root and data volumes remain intact. Only EBS storage is billed (no compute charge).
4. **Shutting-down / Terminated**: Instance is permanently deleted. Root volume is deleted (if `delete_on_termination` is true).

---

## 9. Common EC2 Use Cases
- **Enterprise Web & Application Hosting**: Deploying monolithic or microservice web tiers behind an Application Load Balancer.
- **CI/CD Build Workers**: Self-hosted Jenkins, GitHub Actions, or GitLab runners executing compilation and Docker builds.
- **Database Server Hosting**: Running custom tuned database instances (PostgreSQL, MongoDB) with dedicated provisioned IOPS (`io2`) EBS volumes.
- **Batch Processing & Data Crunching**: Spot EC2 instances executing parallel scientific computing or ETL jobs at up to 90% discount.

---

## 10. [RELEVANT EXTRA INFO] Essential AWS CLI Commands for EC2

```bash
# List and describe running EC2 instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].[InstanceId,InstanceType,PublicIpAddress,State.Name]" \
  --output table

# Launch a new Ubuntu EC2 instance
aws ec2 run-instances \
  --image-id ami-03f4878e83fedf42a \
  --count 1 \
  --instance-type t3.micro \
  --key-name my-devops-key \
  --security-group-ids sg-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0

# Stop an EC2 instance
aws ec2 stop-instances --instance-ids i-0123456789abcdef0

# Start an EC2 instance
aws ec2 start-instances --instance-ids i-0123456789abcdef0

# Terminate an EC2 instance
aws ec2 terminate-instances --instance-ids i-0123456789abcdef0
```

#### 💡 Command Breakdown (cmd-explained):
- `aws ec2 describe-instances`: Queries EC2 API for instances.
  - `--filters "Name=instance-state-name,Values=running"`: Server-side filter to only return currently running instances.
  - `--query "Reservations[*].Instances[*].[...]"`: JMESPath query expression selecting specific fields (Instance ID, type, IP, state).
  - `--output table`: Renders results in an ASCII table instead of JSON.
- `aws ec2 run-instances`: Launches one or more new virtual server instances.
  - `--image-id`: The AMI identifier containing the pre-baked OS.
  - `--instance-type t3.micro`: Hardware compute/memory profile.
  - `--key-name`: Associated SSH key pair name for root authentication.
  - `--security-group-ids`: Firewall rules controlling network packet access.
- `aws ec2 stop-instances`: Gracefully halts instance CPU execution, preserving attached EBS volumes and stopping compute charges.
- `aws ec2 terminate-instances`: Permanently deletes the instance and tears down its root EBS volume.
- `chmod 400 my-key.pem`: Sets Unix permissions so that only the file owner has read access (`400` = `r--------`). SSH rejects private keys with looser permissions (`UNPROTECTED PRIVATE KEY FILE!`).
- `ssh -i my-key.pem ubuntu@<IP>`: Initiates an SSH session using the private identity file (`-i`) connecting as the default user `ubuntu`.

---

### 📚 Tech Jargons Demystified:
- **AMI (Amazon Machine Image):** An immutable pre-configured operating system image template used to launch virtual machine instances.
- **Stateful Firewall (Security Group):** Tracks active network connections so return traffic is automatically allowed, regardless of inbound/outbound rules.
- **EBS (Elastic Block Store):** High-speed block storage attached over the network to EC2 instances, persisting independently of instance reboots.
- **Spot Instances:** Spare AWS compute capacity available at steep discounts (up to 90%), which AWS can reclaim with a 2-minute interruption notice.


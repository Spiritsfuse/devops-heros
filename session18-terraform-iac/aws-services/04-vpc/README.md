# AWS Virtual Private Cloud (VPC) - Networking

## 1. What is VPC?
**Amazon Virtual Private Cloud (Amazon VPC)** enables you to provision a logically isolated section of the AWS Cloud where you can launch AWS resources in a virtual network that you define. You retain complete control over your virtual networking environment, including selection of IP address ranges, subnet creation, routing configuration, and network gateway integration.

---

## 2. CIDR (Classless Inter-Domain Routing)
CIDR notation defines the range of IP addresses assigned to your VPC and subnets using the format: `Base_IP / Prefix_Length` (e.g., `10.0.0.0/16`).
- The prefix specifies how many bits are fixed for the network prefix, leaving the remaining bits for host IP addresses.
- **VPC CIDR Size**: Allowed block sizes range from `/16` (65,536 IP addresses) to `/28` (16 IP addresses).
- **Reserved IPs per Subnet**: In every subnet CIDR block, AWS automatically reserves **5 IP addresses** for internal networking:
  - `.0`: Network address.
  - `.1`: AWS VPC internal router.
  - `.2`: Amazon DNS server (AmazonProvidedDNS).
  - `.3`: Reserved for future AWS expansion.
  - `.255`: Network broadcast address (AWS does not support broadcast, but address is reserved).
  *Example*: A `/24` subnet has 256 theoretical IPs, but only `256 - 5 = 251` usable IPs.

---

## 3. Subnets (Public vs Private)
A **Subnet** is a segment of a VPC's IP address range designated to a specific **Availability Zone (AZ)**.

```text
                      VPC (10.0.0.0/16)
  +-------------------------------------------------------+
  |  Availability Zone A         Availability Zone B      |
  |  +-----------------------+  +-----------------------+ |
  |  | Public Subnet         |  | Public Subnet         | |
  |  | 10.0.1.0/24 (Web/ALB) |  | 10.0.2.0/24 (Web/ALB) | |
  |  +-----------------------+  +-----------------------+ |
  |              |                          |             |
  |              v                          v             |
  |  +-----------------------+  +-----------------------+ |
  |  | Private Subnet        |  | Private Subnet        | |
  |  | 10.0.10.0/24 (Apps)   |  | 10.0.20.0/24 (Apps)   | |
  |  +-----------------------+  +-----------------------+ |
  |              |                          |             |
  |              v                          v             |
  |  +-----------------------+  +-----------------------+ |
  |  | DB Subnet (Private)   |  | DB Subnet (Private)   | |
  |  | 10.0.100.0/24 (RDS)   |  | 10.0.200.0/24 (RDS)   | |
  |  +-----------------------+  +-----------------------+ |
  +-------------------------------------------------------+
```

### Public Subnet:
- Associated with a Route Table that has a default route (`0.0.0.0/0`) pointing directly to an **Internet Gateway (IGW)**.
- Instances launched here can receive public IPv4 addresses and can communicate bi-directionally with the Internet.
- **Typical Use Cases**: Internet-facing Application Load Balancers (ALBs), bastion jump hosts, public reverse proxies.

### Private Subnet:
- Associated with a Route Table that has **no direct route** to an Internet Gateway.
- Instances receive only private IP addresses and are shielded from direct inbound internet access.
- For outbound internet access (e.g., pulling OS security patches or Docker images), traffic is routed through a **NAT Gateway** located in a public subnet.
- **Typical Use Cases**: Backend application microservices, internal worker nodes, databases (RDS / Aurora).

---

## 4. Route Tables
A **Route Table** contains a set of rules (called routes) that determine where network traffic from your subnet or gateway is directed:
- **Local Route**: Every VPC route table contains a default local route (e.g., `10.0.0.0/16 -> local`) enabling all subnets within the VPC to communicate with each other. This route cannot be deleted.
- **Destination & Target**: Each route matches a destination CIDR block and specifies the next-hop target (e.g., `0.0.0.0/0 -> igw-xxxx` or `0.0.0.0/0 -> nat-xxxx`).

---

## 5. Internet Gateway (IGW) vs NAT Gateway

| Feature | Internet Gateway (IGW) | NAT Gateway |
| :--- | :--- | :--- |
| **Purpose** | Connects VPC directly to public Internet | Allows private instances outbound internet access |
| **Traffic Direction** | Bi-directional (both inbound & outbound initiated) | Outbound initiated only; completely blocks inbound internet |
| **Subnet Placement** | Attached to the VPC boundary | Deployed inside a **Public Subnet** |
| **Elastic IP** | Does not require an Elastic IP | Requires an allocated **Elastic IP (EIP)** |
| **Availability** | Highly available, horizontally scaled by AWS | AZ-redundant; must deploy one per AZ for high availability |
| **Pricing** | Free of charge | Hourly rate + per-GB data processing charge |

---

## 6. Security Groups vs Network ACLs (NACLs)

| Feature | Security Groups (SG) | Network ACLs (NACL) |
| :--- | :--- | :--- |
| **Level of Operation** | **Instance Level** (attached to ENI/instance) | **Subnet Level** (guards the subnet boundary) |
| **State Nature** | **Stateful** (return traffic is automatically allowed) | **Stateless** (return traffic must be explicitly allowed) |
| **Rule Types** | **Allow rules only** | Both **Allow and Deny rules** |
| **Rule Order Evaluation** | All rules evaluated simultaneously | Evaluated in strict sequential numerical order (lowest first) |
| **Default Configuration** | Blocks all inbound; allows all outbound | Default NACL allows all; Custom NACL blocks all |

---

## 7. [RELEVANT EXTRA INFO] Essential AWS CLI Commands for VPC

```bash
# Describe existing VPCs
aws ec2 describe-vpcs --output table

# Create a new custom VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Create an Internet Gateway
aws ec2 create-internet-gateway

# Attach the Internet Gateway to your VPC
aws ec2 attach-internet-gateway \
  --vpc-id vpc-0123456789abcdef0 \
  --internet-gateway-id igw-0123456789abcdef0

# Create a Public Subnet
aws ec2 create-subnet \
  --vpc-id vpc-0123456789abcdef0 \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ap-south-1a

# Create a Route to the Internet Gateway for Public Route Table
aws ec2 create-route \
  --route-table-id rtb-0123456789abcdef0 \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-0123456789abcdef0
```

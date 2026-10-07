# Terraform lab

This folder teaches Infrastructure as Code by provisioning the AWS VPC and EKS cluster used by the production-style TaskBoard deployment.

The module-based approach keeps the lesson focused on Terraform concepts: providers, variables, modules, state, plan/apply, outputs and dependency graphs.

> Cost warning: an EKS cluster and NAT gateway can incur AWS charges. Destroy classroom infrastructure when finished.

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
aws eks update-kubeconfig --region ap-south-1 --name taskboard-eks
terraform destroy
```

#### 💡 Command Breakdown (cmd-explained):
- `terraform init`: Initializes the working directory, downloads the AWS provider plugin into `.terraform/`, and configures backend state storage.
- `terraform fmt -recursive`: Formats all `.tf` configuration files in the current directory and all subdirectories according to canonical Terraform conventions and spacing rules.
- `terraform validate`: Statically verifies syntax, attribute names, argument types, and module inputs without making calls to remote cloud APIs.
- `terraform plan`: Constructs an execution dependency graph, refreshes state against live AWS resources, and displays the exact actions (create `+`, update `~`, destroy `-`) Terraform will execute.
- `terraform apply`: Applies the infrastructure changes against AWS API, prompting for a required confirmation `yes` before provisioning the VPC, subnets, NAT gateway, route tables, security groups, and EKS cluster.
- `aws eks update-kubeconfig`: AWS CLI command that queries the EKS cluster endpoints and certificates, then configures your local `~/.kube/config` context with IAM authenticator credentials so `kubectl` can securely talk to the cluster API server:
  - `--region ap-south-1`: Target AWS region where the EKS cluster is hosted (Mumbai).
  - `--name taskboard-eks`: The name of the target EKS cluster to bind.
- `terraform destroy`: Reads current `terraform.tfstate` and tears down all managed AWS resources in reverse dependency order, terminating worker nodes, EKS control plane, and NAT gateways to eliminate ongoing AWS costs.

---

### 📚 Tech Jargons Demystified:
- **EKS (Elastic Kubernetes Service)**: AWS managed Kubernetes control plane. AWS manages the high-availability API servers and etcd quorum across multiple availability zones while you manage the worker node groups.
- **Kubeconfig**: A YAML file (default `~/.kube/config`) containing cluster API server addresses, certificates, user credentials, and contexts used by `kubectl` and `helm` to authenticate and communicate with Kubernetes clusters.
- **NAT Gateway**: A Network Address Translation service in a public subnet allowing private EC2 worker nodes to make outbound internet connections (e.g., to download Docker images from GHCR or apt packages) while blocking inbound traffic from the public internet.
- **Terraform Dependency Graph**: Terraform automatically analyzes references between resources (e.g., node group depends on subnet IDs from VPC module) to construct a Directed Acyclic Graph (DAG), executing non-dependent resource creations in parallel and ordered dependencies sequentially.
- **Module Abstraction**: Grouping reusable sets of Terraform configurations (like VPC + Subnets + Gateways) into a cohesive package with defined inputs (variables) and outputs, keeping code DRY (Don't Repeat Yourself).

# Session 18: Terraform & Infrastructure as Code (IaC)

## 1. Core Concepts: Binary vs Executable (.exe)

- **Source Code**: Human-readable text written by software engineers (e.g., in Go, Python, C). CPUs cannot execute source code directly.
- **Binary**: Machine code composed of compiled `0`s and `1`s specifically built for a CPU architecture (e.g., `x86_64` / `AMD64`, `ARM64`) and an OS kernel.
- **Executable (`.exe` on Windows, binary with `+x` on Linux)**: A compiled program packaged in a format that the OS knows how to load into memory and run.
- **Why double-clicking `terraform.exe` does not work**:
  - Terraform is a **CLI (Command-Line Interface)** tool, not a GUI application.
  - When double-clicked in Windows File Explorer, Windows spawns a terminal for a fraction of a second, prints the help message, and closes immediately.
  - CLI tools must be run from a shell (**Bash in WSL**, **PowerShell**, or **Command Prompt**) where your terminal remains open and arguments (like `terraform init` or `terraform plan`) can be passed.

---

## 2. WSL (Linux) vs Windows: Which Should You Use?

> **Recommendation: Use WSL (Ubuntu)!**
> 
> In real-world DevOps, cloud servers (EC2, GCE), Docker containers, Kubernetes nodes, and CI/CD pipelines (GitHub Actions, GitLab CI, Jenkins) almost exclusively run on **Linux**.
> Running Terraform and the AWS CLI inside WSL ensures:
> - Native Linux file paths and permissions (`chmod 400` for SSH `.pem` keys).
> - Direct alignment with bash scripts and production automation.
> - No line-ending (`CRLF` vs `LF`) issues with shell scripts.

---

## 3. Installation & Verification Status

### Environment 1: WSL (Ubuntu 24.04 LTS) — *(Installed & Verified)*

Both tools are installed and ready:

```bash
# Verify Terraform
terraform -version
# Output: Terraform v1.16.4 on linux_amd64

# Verify AWS CLI
aws --version
# Output: aws-cli/2.37.5 Python/3.14.6 Linux/... exe/x86_64.ubuntu.24
```

#### Commands Used to Install in WSL:

```bash
# 1. Update and install dependencies
sudo apt-get update && sudo apt-get install -y unzip curl gnupg software-properties-common

# 2. Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# 3. Install Terraform via HashiCorp Official Repository
wget -qO- https://apt.releases.hashicorp.com/gpg | gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform
```

---

### Environment 2: Windows Native — *(Status)*

- **AWS CLI**: **Installed** at `C:\Program Files\Amazon\AWSCLIV2\aws.exe` (`aws-cli/2.36.49`).
- **Terraform**: To install on Windows directly via PowerShell (optional):
  ```powershell
  winget install Hashicorp.Terraform --accept-package-agreements --accept-source-agreements
  ```

---

## 4. Next Steps: Configure AWS Credentials

Before running Terraform commands against AWS, configure your AWS credentials inside WSL (or Windows):

```bash
aws configure
```

You will be prompted for:
1. `AWS Access Key ID`: `[Your Access Key]`
2. `AWS Secret Access Key`: `[Your Secret Access Key]`
3. `Default region name`: e.g. `us-east-1` or `ap-south-1`
4. `Default output format`: `json`

Verify connection:
```bash
aws sts get-caller-identity
```

---

## 5. Lecture References

- [Install Terraform CLI - HashiCorp](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Build Infrastructure with Terraform on AWS](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-create)
- [AWS CLI v2 Official Getting Started](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
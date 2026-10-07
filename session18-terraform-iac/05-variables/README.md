# 05 - Variables

Without variables:

```hcl
bucket_prefix = "student-project-dev-"
```

With variables:

```hcl
bucket_prefix = "${var.project_name}-${var.environment}-"
```

Now the same code can be reused for:

```text
dev
test
staging
prod
```

## Variable Structure

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
```

Use it:

```hcl
var.environment
```

## Variable Values

Terraform can receive variables from several sources. For this lab, use `terraform.tfvars`.

Copy:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit if required:

```hcl
aws_region   = "ap-south-1"
environment  = "dev"
project_name = "student-project"
```

## Commands

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

#### 💡 Command Breakdown (cmd-explained):
- `cp terraform.tfvars.example terraform.tfvars`: Copies the template values file into the automatically loaded `terraform.tfvars` file.
- `terraform plan`: Automatically detects and evaluates `terraform.tfvars`, merging user values into variable definitions before calculating the execution diff.
- `var.<name>`: Reference syntax in HCL to access variable values inside resources and local blocks.

You should see a resource using your variable values.

## Important

Do not commit sensitive variable values.

Add this to `.gitignore` in real projects:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
*.tfplan
```

## Exercise

Change:

```hcl
environment = "dev"
```

to:

```hcl
environment = "test"
```

Run:

```bash
terraform plan
```

---

### 📚 Tech Jargons Demystified:
- **Input Variables:** Parameterized inputs allowing Terraform code to be reusable across multiple environments (dev, stage, prod) without changing resource declarations.
- **`terraform.tfvars`:** A standard definition file automatically read by Terraform during plan and apply to assign values to declared variables.
- **Variable Precedence:** The strict order Terraform uses to resolve variable values: CLI flags (`-var`) > `terraform.tfvars` > `*.auto.tfvars` > Environment variables (`TF_VAR_name`) > Defaults.
- **String Interpolation (`"${var.x}-${var.y}"`):** Embedding dynamic variable evaluations directly into strings.

---

## Practice Question:

**Why does changing a variable change the desired infrastructure configuration?**


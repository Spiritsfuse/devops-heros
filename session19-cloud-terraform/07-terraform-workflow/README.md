# 07 - Terraform Workflow

The five commands to remember are:

```text
init
fmt
validate
plan
apply
```

And one very important cleanup command:

```text
destroy
```

---

# 1. terraform init

```bash
terraform init
```

Think:

> "Prepare this Terraform folder."

It downloads providers and prepares the working directory.

Expected:

```text
Terraform has been successfully initialized!
```

---

# 2. terraform fmt

```bash
terraform fmt
```

Think:

> "Make my Terraform code look clean."

---

# 3. terraform validate

```bash
terraform validate
```

Think:

> "Is my Terraform configuration valid?"

Expected:

```text
Success! The configuration is valid.
```

---

# 4. terraform plan

```bash
terraform plan
```

Think:

> "Show me what you are going to do."

Example:

```text
+ create
~ update
- destroy
-/+ replace
```

For this tiny demo:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

---

# 5. terraform apply

```bash
terraform apply
```

Think:

> "Actually do it."

Terraform asks for confirmation.

```text
Enter a value:
```

Enter:

```text
yes
```

---

# 6. terraform output

```bash
terraform output
```

Shows values defined in Terraform `output` blocks.

---

# 7. terraform state list

```bash
terraform state list
```

Shows resources Terraform currently tracks.

Example:

```text
aws_s3_bucket.demo
```

---

# 8. terraform destroy

```bash
terraform destroy
```

Think:

> "Remove the infrastructure Terraform created."

Always understand what you are destroying before entering `yes`.

---

# Complete Flow

```text
              .tf files
                  |
                  v
            terraform init
                  |
                  v
             terraform fmt
                  |
                  v
          terraform validate
                  |
                  v
            terraform plan
                  |
                  v
           terraform apply
                  |
                  v
              Cloud
                  |
                  v
          terraform state
                  |
                  v
           terraform destroy
```

---

# Demo

Run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Check:

```bash
terraform state list
```

Then:

```bash
terraform destroy
```

#### 💡 Command Breakdown (cmd-explained):
- `terraform init`: Prepares working directory, configures backend, and installs required provider plugins (`.terraform/`).
- `terraform fmt`: Rewrites `.tf` files into standard HCL canonical formatting and indentation.
- `terraform validate`: Statically verifies internal syntax, configuration arguments, and variable types without making remote cloud calls.
- `terraform plan`: Reads current state and remote resources, generating an execution plan predicting additions (`+`), changes (`~`), and removals (`-`).
- `terraform apply`: Applies planned changes to the cloud provider, asking for interactive confirmation (`yes`).
- `terraform state list`: Dumps all resource addresses recorded in the active state database.
- `terraform destroy`: De-provisions all managed cloud infrastructure tracked in state.

---

### 📚 Tech Jargons Demystified:
- **Canonical Formatting (`fmt`):** A strict, automated code styling standard universally adopted by the Terraform ecosystem, eliminating stylistic arguments in team pull requests.
- **Syntactic vs Semantic Validation:** Syntactic checks ensure your HCL has matching braces and quotes; semantic validation checks that referenced variables, providers, and attributes actually exist.
- **Topological Sort:** The algorithm Terraform Core uses to order resource creation based on explicit and implicit dependencies (e.g. creating the VPC before creating the Subnet).
- **Blast Radius:** The scope of cloud infrastructure impacted if a plan is applied or destroyed incorrectly. Minimizing blast radius is achieved through smaller, decoupled Terraform configurations.

---

# Practice Questions

1. Which command downloads providers?
2. Which command formats Terraform code?
3. Which command checks configuration syntax and consistency?
4. Which command shows changes without applying them?
5. Which command actually creates resources?
6. Which command removes resources?


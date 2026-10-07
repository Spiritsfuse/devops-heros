# 08 - Terraform Destroy

Terraform can remove infrastructure that it manages.

Command:

```bash
terraform destroy
```

Terraform creates a destroy plan and asks for confirmation.

## Before Destroy

Check:

```bash
terraform state list
```

Example:

```text
aws_s3_bucket.lifecycle_demo
```

## Destroy

```bash
terraform destroy
```

Expected:

```text
Terraform will perform the following actions:

  # aws_s3_bucket.lifecycle_demo will be destroyed
  - resource "aws_s3_bucket" "lifecycle_demo" {
      ...
    }

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Only 'yes' will be accepted to confirm.

Enter a value: yes
```

Then:

```text
aws_s3_bucket.lifecycle_demo: Destroying...
aws_s3_bucket.lifecycle_demo: Destruction complete after ...s

Destroy complete! Resources: 1 destroyed.
```

Terraform documents `destroy` as a destroy-mode plan followed by an approval before resources are removed.

## Important Warning

Destroy means **delete real infrastructure**.

Always inspect:

```bash
terraform plan -destroy
```

before:

```bash
terraform destroy
```

#### 💡 Command Breakdown (cmd-explained):
- `terraform plan -destroy`: Generates an execution plan specifically showing what resources would be deleted, without actually modifying real infrastructure. Allows safe auditing.
- `terraform destroy`: Executes the destruction of all tracked infrastructure resources in the state file in reverse topological dependency order.
- `terraform destroy -target=<resource_address>`: Destroys only a specific targeted resource (e.g. `-target=aws_s3_bucket.lifecycle_demo`) while leaving other infrastructure intact. (Use with caution).
- `-auto-approve`: CLI flag that bypasses the interactive `Enter a value: yes` confirmation prompt (recommended only in non-interactive CI/CD teardown pipelines).

---

### 📚 Tech Jargons Demystified:
- **Tear-Down / De-provisioning:** Completely removing cloud infrastructure when no longer needed to prevent ongoing financial charges.
- **Dependency Inversion on Destroy:** When creating, dependencies are created first (e.g. VPC -> Subnet -> EC2); when destroying, Terraform automatically reverses the dependency tree (EC2 -> Subnet -> VPC).
- **Prevent Destroy Lifecycle (`lifecycle { prevent_destroy = true }`):** A safety guard in HCL that causes Terraform to reject any attempt to destroy a mission-critical resource (like a production database or customer data bucket).
- **Orphaned Resources:** Real-world cloud resources left running and incurring costs if they are removed from the Terraform configuration without running destroy or state rm.

---

## Practice Questions:

1. What is the difference between `plan` and `apply`?
2. What does `destroy` do?
3. Why should we run `plan -destroy` before deleting production infrastructure?


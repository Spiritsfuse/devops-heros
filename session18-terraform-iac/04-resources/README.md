# 04 - Resources

A resource represents infrastructure managed by Terraform.

General syntax:

```hcl
resource "RESOURCE_TYPE" "LOCAL_NAME" {
  argument = value
}
```

Example:

```hcl
resource "aws_s3_bucket" "demo" {
  bucket_prefix = "session18-resource-"
}
```

Here:

| Part | Meaning |
|---|---|
| `resource` | Terraform resource block |
| `aws_s3_bucket` | Resource type |
| `demo` | Terraform local name |
| `bucket_prefix` | Resource argument |

Terraform's AWS provider exposes an `aws_s3_bucket` resource for managing general-purpose S3 buckets.

## Commands

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Expected plan:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

After apply:

```bash
terraform state list
```

Expected:

```text
aws_s3_bucket.demo
```

## Inspect the resource

```bash
terraform show
```

#### 💡 Command Breakdown (cmd-explained):
- `terraform show`: Displays all state metadata and provider attributes (such as `arn`, `bucket_domain_name`, `hosted_zone_id`) computed by AWS during bucket provisioning.
- `terraform fmt`: Formats HCL syntax, aligning assignment operators (`=`) and indentations automatically.
- `terraform state list`: Confirms the local identifier `aws_s3_bucket.demo` is registered in state.

## Cleanup

```bash
terraform destroy
```

Expected:

```text
Plan: 0 to add, 0 to change, 1 to destroy.

Destroy complete! Resources: 1 destroyed.
```

## Exercise

Add tags:

```hcl
tags = {
  Project     = "terraform-training"
  Environment = "dev"
  Owner       = "student"
}
```

Run:

```bash
terraform fmt
terraform plan
```

---

### 📚 Tech Jargons Demystified:
- **Resource Block:** The fundamental building block in Terraform (`resource "type" "name"`) declaring a physical or virtual infrastructure component.
- **Computed Attributes:** Attributes whose values are not known until the resource is created in the cloud (e.g. bucket ARN, creation date, regional domain name).
- **Resource Addressing:** The reference syntax `aws_s3_bucket.demo` used by other resources or outputs to link configuration objects.
- **In-Place Modification (`~`):** A plan status indicating that adding or editing attributes (like tags) will update the resource live without destroying and recreating it.


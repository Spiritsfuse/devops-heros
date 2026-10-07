# 06 - Outputs

Outputs expose useful values from Terraform.

Example:

```hcl
output "bucket_id" {
  value = aws_s3_bucket.demo.id
}
```

## Apply

```bash
terraform init
terraform plan
terraform apply
```

After approval:

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn    = "arn:aws:s3:::session18-output-xxxxxxxx"
bucket_id     = "session18-output-xxxxxxxx"
bucket_region = "ap-south-1"
```

The exact bucket name is generated dynamically.

## Read outputs

```bash
terraform output
```

Read one output:

```bash
terraform output bucket_id
```

#### 💡 Command Breakdown (cmd-explained):
- `terraform output`: Dumps all exposed root module output values in key-value format directly to terminal output.
- `terraform output bucket_id`: Queries state specifically for the named output `bucket_id`.
- `terraform output -raw <name>`: Prints only the raw string value without quotes or formatting, ideal for piping into shell scripts or environment variables.
- `terraform output -json`: Dumps outputs as a JSON object, ideal for CI/CD automation parsers (`jq`).

Example:

```text
session18-output-xxxxxxxx
```

## Why Outputs Matter

Outputs are useful when:

- Passing information to another module
- Displaying resource IDs
- Feeding values into automation
- CI/CD pipelines
- Sharing infrastructure information

## Exercise

Add:

```hcl
output "bucket_name" {
  value = aws_s3_bucket.demo.bucket
}
```

Then run:

```bash
terraform apply
terraform output bucket_name
```

---

### 📚 Tech Jargons Demystified:
- **Output Values:** Named return values declared in configuration (`output "name" { value = ... }`) allowing Terraform to expose created resource attributes.
- **Cross-Stack Integration:** Using outputs to feed identifiers (like VPC subnet IDs or database connection strings) from one Terraform workspace/state into another via `terraform_remote_state`.
- **Sensitive Outputs (`sensitive = true`):** Flag hiding database passwords or private keys from CLI terminal outputs while still storing them securely in the state file.
- **Root Module vs Child Module Outputs:** Child module outputs are used by parent modules to pass values; root module outputs are displayed to the user after `terraform apply`.


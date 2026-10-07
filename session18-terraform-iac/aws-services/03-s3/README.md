# AWS Simple Storage Service (S3) - Storage

## 1. What is S3?
**Amazon Simple Storage Service (Amazon S3)** is an industry-leading object storage service offering 99.999999999% (11 9's) of data durability, industry-standard scalability, high data availability, and fine-grained security. 

Unlike **Block Storage** (like EBS, which stores data as raw volume blocks) or **File Storage** (like EFS, which manages hierarchical file system directory trees), **Object Storage** manages data as flat, independent units called **Objects**, each packaged with unique keys, extensive metadata, and access permissions.

---

## 2. Buckets & Objects

### Buckets
A **Bucket** is a top-level container for objects stored in Amazon S3:
- **Global Uniqueness**: Bucket names must be globally unique across all AWS accounts worldwide.
- **DNS-Compliant Naming**: Names must be between 3 and 63 characters long, consist only of lowercase letters, numbers, hyphens (`-`), and must not resemble IP addresses.
- **Regional Deployment**: Although bucket names are globally unique, each bucket is physically created inside a chosen AWS Region (e.g., `ap-south-1` Mumbai) to optimize latency and satisfy data sovereignty requirements.

### Objects
An **Object** is the fundamental entity stored in Amazon S3:
- **Key**: The unique name/identifier assigned to the object within the bucket (e.g., `logs/2026/09/access.log`). S3 creates a flat structure; slashes (`/`) serve as visual prefixes in the console.
- **Value**: The raw binary data payload (size ranges from 0 bytes up to **5 Terabytes** per single object; uploads > 5GB require multi-part uploads).
- **Version ID**: Identifies the specific revision when bucket versioning is enabled.
- **Metadata**: Key-value pairs providing data attributes (system metadata like `Content-Type`, `Last-Modified`, and custom user metadata).
- **Access Control Information**: Permissions dictating who can read, modify, or delete the object.

---

## 3. Storage Classes

AWS provides multiple S3 storage classes designed to balance access latency and storage costs:

| Storage Class | Durability | Availability | Retrieval Fee | Typical Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **S3 Standard** | 99.999999999% | 99.99% | None | Frequently accessed active data, web content, dynamic mobile apps |
| **S3 Intelligent-Tiering** | 99.999999999% | 99.9% | Small auto-monitoring fee | Workloads with unknown, changing, or unpredictable access patterns |
| **S3 Standard-Infrequent Access (IA)** | 99.999999999% | 99.9% | Yes (per GB) | Long-lived, infrequently accessed backups and disaster recovery data |
| **S3 One Zone-IA** | 99.999999999% (single AZ) | 99.5% | Yes (per GB) | Non-critical, easily reproducible secondary backup data |
| **S3 Glacier Instant Retrieval** | 99.999999999% | 99.9% | Yes | Medical records, media archives accessed once a quarter with ms retrieval |
| **S3 Glacier Flexible Retrieval** | 99.999999999% | 99.9% | Yes | Archival data retrievable in minutes to hours (1 min to 12 hrs) |
| **S3 Glacier Deep Archive** | 99.999999999% | 99.9% | Yes | Lowest cost cloud storage (7-10+ year compliance retention, 12-48 hr retrieval) |

---

## 4. Versioning
**S3 Versioning** maintains multiple variants of an object in the same bucket:
- **Accidental Deletion Protection**: When an object is deleted, S3 does not permanently erase it; instead, it inserts a **Delete Marker**. The object can be recovered by removing the delete marker.
- **Accidental Overwrites**: Overwriting an object creates a new version with a new Version ID, preserving the original version history.
- **MFA Delete**: Adds an additional layer of security by requiring multi-factor authentication to permanently delete an object version or alter bucket versioning state.

---

## 5. Lifecycle Policies
**S3 Lifecycle Management** allows you to automate data transition and expiration workflows across the lifecycle of your objects:
- **Transition Actions**: Automatically move objects to cheaper storage classes based on age (e.g., transition to *Standard-IA* after 30 days, to *Glacier Flexible* after 90 days).
- **Expiration Actions**: Automatically delete objects after a specified period (e.g., delete noncurrent versions after 365 days, purge temporary logs after 14 days).
- **Incomplete Multipart Upload Cleanup**: Abort and delete lingering uncompleted multipart upload parts to avoid paying for orphaned storage blocks.

---

## 6. S3 Encryption

### Server-Side Encryption (SSE):
Data is encrypted at rest within the AWS data center before being written to disk:
1. **SSE-S3 (AES-256)**: S3 manages the encryption keys automatically at zero extra cost. (Enabled by default for all new S3 buckets).
2. **SSE-KMS (AWS KMS)**: Uses keys managed in AWS Key Management Service (KMS), providing audit trails via CloudTrail and key rotation governance.
3. **SSE-C (Customer-Provided Keys)**: You supply your own cryptographic keys with each API request; AWS performs encryption but does not store your keys.

### Client-Side Encryption:
Data is encrypted locally on the client machine before transmission over the network to Amazon S3.

---

## 7. Bucket Policies
An **S3 Bucket Policy** is a resource-based IAM policy attached directly to the bucket, granting or restricting access from various principals, IP ranges, or protocols.

### Example: Enforce HTTPS (TLS) Only
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnforceTLSRequestsOnly",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::spirits5510",
        "arn:aws:s3:::spirits5510/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

---

## 8. Common S3 Use Cases
- **Terraform Remote State Backend**: Storing `terraform.tfstate` with state locking via DynamoDB.
- **Static Website Hosting**: Serving single-page applications (React, Vue, HTML/CSS) directly from an S3 bucket with CloudFront CDN.
- **Data Lake Storage**: Central raw and processed storage for analytics tools like Amazon Athena, AWS Glue, and EMR.
- **Backup & Disaster Recovery**: Storing database dumps, system snapshots, and compliance archives.

---

## 9. [RELEVANT EXTRA INFO] Essential AWS CLI Commands for S3

```bash
# List all S3 buckets in your AWS account
aws s3 ls

# List contents of a specific bucket
aws s3 ls s3://spirits5510/

# Create a new bucket in ap-south-1
aws s3 mb s3://my-devops-unique-bucket-2026 --region ap-south-1

# Upload a file to an S3 bucket
aws s3 cp app.zip s3://spirits5510/builds/app.zip

# Recursively sync a local directory to S3
aws s3 sync ./dist s3://spirits5510/frontend/

# Download an object from S3
aws s3 cp s3://spirits5510/builds/app.zip ./app-downloaded.zip

# Inspect bucket metadata & verify existence
aws s3api head-bucket --bucket spirits5510

# Delete an object
aws s3 rm s3://spirits5510/builds/app.zip

# Remove an entire bucket and all its contents
aws s3 rb s3://spirits5510 --force
```

#### 💡 Command Breakdown (cmd-explained):
- `aws s3 ls`: Lists all S3 buckets in your AWS account or directory prefixes inside a bucket.
- `aws s3 mb s3://<bucket> --region <region>`: "Make bucket". Provisions a brand-new S3 bucket in the specified AWS geographical region.
- `aws s3 cp <src> <dest>`: Copies files between local disks and S3 buckets, or bucket-to-bucket.
- `aws s3 sync ./dist s3://...`: Compares modified timestamps and file sizes, uploading only changed or new files recursively to minimize network data transfer.
- `aws s3api head-bucket`: Determines if a bucket exists and you have access permissions without querying contents.
- `aws s3 rm`: Removes an object from the bucket.
- `aws s3 rb --force`: "Remove bucket". Deletes the bucket; the `--force` flag first empties all objects inside the bucket before destroying it.

---

### 📚 Tech Jargons Demystified:
- **Object Storage vs Block Storage:** Object storage (S3) manages data as flat files with rich metadata accessed over HTTP REST APIs; block storage (EBS) manages raw sectors directly attached to an OS filesystem.
- **11 9's of Durability (99.999999999%):** Statistical probability that an object will not be lost across a year; achieved by S3 automatically replicating objects redundantly across at least 3 physical Availability Zones.
- **Delete Marker:** A dummy placeholder object inserted by S3 Versioning when an object is deleted, preventing permanent data loss.
- **S3 Intelligent-Tiering:** An autonomous storage class that monitors access frequencies and shifts objects between frequent and infrequent tiers without retrieval fees.


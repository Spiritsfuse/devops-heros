# AWS Identity and Access Management (IAM) - Governance

## 1. What is IAM?
**AWS Identity and Access Management (IAM)** is a global web service that helps you securely control access to AWS resources. IAM enables you to manage **Authentication** (who can sign in - verification of identity) and **Authorization** (what permissions they have - access control to AWS services and resources).

Key properties of IAM:
- **Global Service**: IAM is not tied to a specific AWS region; users, groups, roles, and policies apply globally across all AWS regions.
- **Zero Cost**: IAM is offered at no additional charge; you are billed only for other AWS resources accessed by IAM entities.
- **Centralized Security Management**: Offers fine-grained access control for every API call made in AWS.

---

## 2. Core IAM Entities

### Users
An **IAM User** represents a human user or an interactive service account that needs to interact with AWS resources.
- Each user consists of a friendly name and permanent credentials (either a **password** for the AWS Management Console or **Access Keys** for the AWS CLI / SDKs).
- **Default State**: A newly created IAM user has **no permissions** (implicit deny). Permissions must be explicitly granted via policies.

### Groups
An **IAM Group** is a collection of IAM users. 
- Groups allow administrators to assign permissions to multiple users at once, simplifying permission management.
- *Key constraints*:
  - Groups cannot be nested (a group cannot contain another group).
  - Groups do not have credentials of their own; they only inherit policies.
  - A user can belong to multiple groups (up to 10 by default, soft limit).

### Roles
An **IAM Role** is an IAM identity that you can create in your account that has specific permissions, but is **not associated with a specific person**. Instead, it is intended to be **assumed** by anyone who needs it:
- **Temporary Security Credentials**: When an entity assumes a role, AWS Security Token Service (STS) issues short-lived credentials (Access Key, Secret Key, and Session Token) that automatically expire (from 15 minutes up to 12 hours).
- **Common Role Users**:
  - AWS Services (e.g., an EC2 instance or ECS task needing to read from S3 via an *Instance Profile*).
  - Federated Users (external identity providers using SAML 2.0 or OIDC such as Google, Okta, or Active Directory).
  - Cross-Account Access (delegating access to resources in Account B from Account A without sharing access keys).

---

## 3. Policies & Permissions

### Policies
An **IAM Policy** is a JSON document that explicitly defines permissions. AWS evaluates policies to allow or deny actions on resources.

#### Policy Structure
An IAM policy contains one or more `Statement` blocks:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadWriteDevOps",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::spirits5510",
        "arn:aws:s3:::spirits5510/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    }
  ]
}
```
- **Effect**: Specifies whether the policy allows or denies access (`Allow` or `Deny`).
- **Principal**: The entity (user, account, role) allowed or denied (used in resource-based policies; omitted in identity-based policies).
- **Action**: The specific API operations allowed or denied (e.g., `s3:GetObject`, `ec2:RunInstances`).
- **Resource**: The Amazon Resource Name (ARN) of the target AWS resource.
- **Condition** *(Optional)*: The circumstances under which the policy grants or denies permission (e.g., source IP, MFA status, SSL only).

#### Policy Types
1. **AWS Managed Policies**: Pre-created and maintained by AWS (e.g., `AdministratorAccess`, `AmazonS3ReadOnlyAccess`). Fast to attach but cannot be edited.
2. **Customer Managed Policies**: Custom JSON policies created within your account. Provide fine-grained control and support versioning.
3. **Inline Policies**: Embedded directly into a single user, group, or role. When the entity is deleted, the inline policy is destroyed with it.

### Permissions Evaluation Logic
1. **Explicit Deny**: If any applicable policy statement has `"Effect": "Deny"`, the request is denied immediately.
2. **Default Deny**: By default, all requests are implicitly denied unless an explicit allow exists.
3. **Explicit Allow**: A request is authorized only if there is an explicit `"Effect": "Allow"` and no explicit deny.

---

## 4. Least Privilege Principle
The **Principle of Least Privilege (PoLP)** states that users, applications, and services should be granted **only the minimum permissions required** to perform their designated tasks, and for no longer than necessary.

### How to Enforce Least Privilege:
1. Start with zero permissions and incrementally grant actions based on actual operational needs.
2. Scope policies to specific resource ARNs rather than using wildcards (`*`).
3. Use **IAM Access Analyzer** to review access paths and detect overly permissive resource policies.
4. Utilize **Permission Boundaries** to set the maximum allowed permissions an IAM entity can have, preventing privilege escalation.

---

## 5. IAM Best Practices
1. **Lock Down the AWS Root User**:
   - Never use the root user for day-to-day administration.
   - Enable hardware or authenticator MFA on the root account.
   - Delete all root access keys.
2. **Enforce Multi-Factor Authentication (MFA)**:
   - Require MFA for all IAM users with console access and administrative privileges.
3. **Use Roles for Applications and EC2 Instances**:
   - Never hardcode AWS access keys inside application code or EC2 instances.
   - Attach IAM Roles to instances via instance profiles.
4. **Regular Credential Rotation**:
   - Rotate access keys every 90 days. Deactivate unused keys immediately.
5. **Enforce Strong Password Policies**:
   - Minimum length (12+ characters), uppercase, lowercase, numbers, symbols, and automatic password expiration.
6. **Use Groups to Assign Permissions**:
   - Do not attach policies directly to individual users; assign users to role-based groups.
7. **Audit with AWS CloudTrail and Access Advisor**:
   - Review CloudTrail logs to track who performed which API action and remove unused permissions.

---

## 6. Common IAM Use Cases
- **EC2 Instance Profile**: Granting an EC2 web server permission to read configuration files from an S3 bucket without embedding credentials in the VM.
- **CI/CD Pipeline Security (GitHub Actions / GitLab CI)**: Using OIDC federation with IAM Roles to let CI/CD runners deploy infrastructure without long-lived secret access keys.
- **Cross-Account Administrative Access**: Allowing security auditors from a centralized Audit Account to assume read-only roles in Production and Staging accounts.
- **Emergency Break-Glass Access**: Controlled high-privilege IAM roles guarded by tight CloudWatch alerts for incident response.

---

## 7. [RELEVANT EXTRA INFO] Essential AWS CLI Commands for IAM

```bash
# Verify current authenticated identity and account details
aws sts get-caller-identity

# List all IAM users in the account
aws iam list-users

# Create a new IAM user
aws iam create-user --user-name devops-engineer

# Create an access key pair for programmatic access
aws iam create-access-key --user-name devops-engineer

# Attach a managed policy to a user
aws iam attach-user-policy \
  --user-name devops-engineer \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# List policies attached to a user
aws iam list-attached-user-policies --user-name devops-engineer

# Create an IAM role with an EC2 trust policy
aws iam create-role \
  --role-name S3ReadOnlyEC2Role \
  --assume-role-policy-document file://trust-policy.json
```

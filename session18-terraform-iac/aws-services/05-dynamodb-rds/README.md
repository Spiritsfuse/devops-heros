# AWS Database Services: DynamoDB & RDS

## 1. Overview: NoSQL vs Relational Databases
AWS offers specialized database engines tailored for specific data access patterns:
- **NoSQL (Amazon DynamoDB)**: Highly optimized for horizontal scale, predictable single-digit millisecond latency at any throughput, and semi-structured key-value or document data.
- **Relational / RDBMS (Amazon RDS)**: Optimized for complex relational modeling, ACID transactions, join queries, and structured schema governance.

---

## 2. Amazon DynamoDB (NoSQL)

### Core Architecture:
Amazon DynamoDB is a fully managed, serverless, key-value and document database designed for blazing-fast performance at any scale.

### Key Concepts:
1. **Tables**: A collection of data items (similar to a table in SQL or a collection in MongoDB). Unlike relational tables, DynamoDB tables are **schemaless** (items can have different attributes, except for the primary key).
2. **Items**: A single record within a table (analogous to a row in SQL). Maximum item size is **400 KB**.
3. **Attributes**: Fundamental data elements inside an item (similar to columns or JSON key-value fields), supporting scalar types (String, Number, Binary, Boolean, Null), document types (List, Map), and set types.

### Primary Keys:
- **Partition Key (HASH Key)**: A single attribute that determines the physical partition where the item is stored using an internal hash function.
- **Composite Primary Key (Partition Key + Sort Key / HASH + RANGE)**: Allows multiple items to share the same partition key while being sorted in order by the sort key (e.g., `UserID` [Partition Key] + `Timestamp` [Sort Key]).

### Secondary Indexes:
- **Global Secondary Index (GSI)**: An index with a partition key and sort key that can be different from those on the base table. Can be created or deleted anytime.
- **Local Secondary Index (LSI)**: An index that has the same partition key as the table, but a different sort key. Must be created at table creation time.

### Capacity Modes:
- **On-Demand**: Automatically scales up and down to match application traffic with zero capacity planning. Pay strictly per read/write request.
- **Provisioned**: Pre-allocate Read Capacity Units (RCUs) and Write Capacity Units (WCUs) with optional auto-scaling. Cost-effective for predictable workloads.

### DynamoDB Use Cases:
- **Session State Management**: Storing user authentication sessions, tokens, and shopping carts.
- **Gaming Leaderboards**: Real-time user scores, player state, and match histories.
- **IoT & Telemetry**: Ingesting high-velocity sensor data streams.
- **Terraform State Locking**: Locking `terraform.tfstate` during concurrent team deployments to avoid race conditions.

---

## 3. Amazon Relational Database Service (Amazon RDS)

### Core Architecture:
Amazon RDS is a managed service that makes it easy to set up, operate, and scale relational databases in the cloud. AWS automates time-consuming administrative tasks like hardware provisioning, database setup, patching, backups, and failover.

### Supported Database Engines:
1. **Amazon Aurora** (MySQL & PostgreSQL compatible, cloud-native storage architecture)
2. **PostgreSQL**
3. **MySQL**
4. **MariaDB**
5. **Oracle Database**
6. **Microsoft SQL Server**

### DB Instances & Compute Classes:
- **Standard Classes** (`db.m6i`, `db.m7g`): Balanced compute and memory.
- **Memory-Optimized Classes** (`db.r6i`, `db.r7g`): Heavy memory capacity for caching and enterprise databases.
- **Burstable Performance Classes** (`db.t3`, `db.t4g`): Cost-effective baseline compute with CPU bursting capability for dev/test.

### Security in RDS:
- **VPC Isolation**: RDS instances run inside private subnets within your VPC, protected by DB Subnet Groups and Security Groups.
- **Encryption at Rest**: Fully integrated with AWS KMS (AES-256) encrypting data, automated backups, and read replicas.
- **Encryption in Transit**: SSL/TLS enforced connections between clients and the database engine.
- **Authentication**: Native database authentication or centralized **IAM Database Authentication** (no stored passwords).

### Automated Backups & Snapshots:
- **Automated Backups**: Continuous daily snapshots + transaction logs stored in S3, providing **Point-in-Time Recovery (PITR)** down to the second within a configurable retention period (1 to 35 days).
- **Manual DB Snapshots**: User-initiated manual backups that persist indefinitely until explicitly deleted.

### High Availability: Multi-AZ Deployments:
- AWS automatically provisions and maintains a **synchronous standby replica** in a different Availability Zone.
- If the primary DB instance encounters an outage, storage failure, or routine maintenance, RDS triggers an **automatic failover** to the standby within 60–120 seconds with **zero DNS endpoint changes**.

### Scaling: Read Replicas:
- **Asynchronous Replication**: Read Replicas offload read traffic from the primary master database.
- Up to 15 read replicas (in Amazon Aurora) can be deployed across multiple AZs or regions.
- Applications route write queries (`INSERT`, `UPDATE`, `DELETE`) to the primary endpoint, and read queries (`SELECT`) to the read replica endpoints.

### RDS Use Cases:
- **Traditional Enterprise ERP & CRM Applications**: SAP, Salesforce custom backends, financial bookkeeping.
- **Transactional E-Commerce**: Systems requiring strict ACID compliance, complex JOIN operations, and relational integrity.
- **Content Management Systems (CMS)**: WordPress, Drupal, Magento running on MySQL/MariaDB.

---

## 4. DynamoDB vs RDS Feature Matrix

| Feature | Amazon DynamoDB | Amazon RDS |
| :--- | :--- | :--- |
| **Model Type** | NoSQL (Key-Value / Document) | Relational (RDBMS) |
| **Schema** | Flexible / Dynamic Schema | Rigid / Predefined Schema |
| **Scaling Mechanism** | **Horizontal Scaling** (partitioning) | Primarily **Vertical Scaling** (CPU/RAM sizing; Read Replicas for reads) |
| **Performance** | Consistent single-digit millisecond latency | Variable depending on query complexity & indexing |
| **High Availability** | Built-in automatically across 3 AZs | Multi-AZ option (synchronous standby) |
| **Join Queries** | Not supported (denormalized design) | Native SQL JOIN support |
| **Serverless Option** | Yes (DynamoDB On-Demand) | Yes (Amazon Aurora Serverless v2) |
| **State Locking in DevOps**| Standard for Terraform state locking | Not typically used for state locking |

---

## 5. [RELEVANT EXTRA INFO] Essential AWS CLI Commands for DynamoDB & RDS

```bash
# List all DynamoDB tables
aws dynamodb list-tables

# Describe a DynamoDB table
aws dynamodb describe-table --table-name devops-state-lock

# Put an item into a DynamoDB table
aws dynamodb put-item \
  --table-name Users \
  --item '{"UserId": {"S": "u101"}, "Name": {"S": "Dhruv Sharma"}, "Role": {"S": "DevOps Lead"}}'

# Describe all RDS DB instances
aws rds describe-db-instances \
  --query "DBInstances[*].[DBInstanceIdentifier,Engine,DBInstanceStatus,Endpoint.Address]" \
  --output table

# Create a manual DB snapshot of an RDS database
aws rds create-db-snapshot \
  --db-instance-identifier production-db \
  --db-snapshot-identifier production-db-manual-backup-2026
```

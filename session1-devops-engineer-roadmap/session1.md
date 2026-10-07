# Introduction to DevOps, Microservices & Cloud Architecture

## Student Information
- **Name:** Dhruv Sharma
- **Enrollment Number (Roll No):** 24BCS10294
- **Track:** DevOps, Cloud & Systems Engineering

---

## 1. Monolith vs Microservices Architecture

```text
       MONOLITHIC ARCHITECTURE                      MICROSERVICES ARCHITECTURE
+------------------------------------+     +------------------+     +------------------+
|          Single Codebase           |     |  Auth Service    |     |  Order Service   |
|   (UI + Auth + Cart + Payments)    |     |  (Node.js + PG)  |     |  (Go + Redis)    |
|                 ↓                  |     +--------+---------+     +--------+---------+
|     Shared Monolithic Database     |              \                   /
|            (Single DB)             |               v                 v
+------------------------------------+          +---------------------------+
                                                |     API Gateway / Ingress |
                                                +---------------------------+
                                                             |
                                                    +--------v---------+
                                                    | Payment Service  |
                                                    | (Python + MySQL) |
                                                    +------------------+
```

### Architectural Comparison

| Dimension | Monolithic Architecture | Microservices Architecture |
| :--- | :--- | :--- |
| **Codebase** | Single repository containing all features | Modular repositories separated by business domains |
| **Deployments** | All-or-nothing (high blast radius) | Independent zero-downtime micro-deployments |
| **Scalability** | Scale entire application horizontally | Scale only the bottleneck service (e.g. Orders) |
| **Tech Stack** | Locked into one primary language/runtime | Polyglot (use best tool for each domain) |
| **Database** | Centralized shared schema | Database-per-service (loose coupling) |
| **Failure Mode** | Memory leak in one module brings down all | Fault isolation (circuit breakers prevent cascades) |

---

## 2. What is DevOps & The DevOps Lifecycle?

> **DevOps** is a cultural philosophy, set of practices, and toolchain that merges software development (**Dev**) and IT operations (**Ops**) to deliver high-quality software continuously and reliably.

### The DevOps Infinite Loop

```text
       [PLAN] ➔ [CODE] ➔ [BUILD] ➔ [TEST]
         ^                             |
         |                             v
      [MONITOR] ⮜ [OPERATE] ⮜ [DEPLOY] ⮜ [RELEASE]
```

1. **Plan:** Agile user stories, Jira boards, architecture definitions.
2. **Code:** Git branching, peer code reviews, pull requests.
3. **Build:** Compiling binaries, packaging multi-stage Docker images.
4. **Test:** Automated unit tests, integration tests, linting, SAST scanning.
5. **Release:** Tagging immutable container images, Helm chart versioning.
6. **Deploy:** GitOps (Argo CD), blue-green / canary rollouts on Kubernetes.
7. **Operate:** Infrastructure as Code (Terraform), autoscaling (HPA).
8. **Monitor:** Prometheus metrics, Grafana dashboards, distributed tracing.

---

## 3. Essential DevOps Starter Workflow Commands

```bash
# 1. Clone source repository and switch to a feature branch
git clone https://github.com/Spiritsfuse/devops-heros.git
cd devops-heros
git checkout -b feature/setup-ci-pipeline

# 2. Verify local development runtime prerequisites
docker --version
kubectl version --client --output=yaml
terraform version

# 3. Inspect system resources and network readiness
uname -a
df -h /
uptime
```

#### 💡 Command Breakdown (cmd-explained):
- `git clone <url>`: Copies the remote Git repository, history, branches, and commits down to your local machine.
- `git checkout -b <branch>`: Creates a new feature branch and immediately switches the working tree to it, isolating new features from `main`.
- `docker --version`: Verifies the Docker Engine client binary is installed and reachable in your system `PATH`.
- `kubectl version --client --output=yaml`: Inspects the Kubernetes CLI version in structured YAML format without attempting to connect to a remote cluster API server.
- `terraform version`: Verifies HashiCorp Terraform CLI binary version and flags any available updates.
- `uname -a`: Prints full Linux operating system and kernel architecture details (`Linux hostname kernel-version x86_64 GNU/Linux`).
- `df -h /`: Reports root filesystem disk space usage in human-readable units (Gigabytes/Megabytes).
- `uptime`: Displays system uptime, number of logged-in sessions, and the 1, 5, and 15-minute load averages.

---

### 📚 Tech Jargons Demystified:
- **Monolith**: A software architecture where all functional components (UI, business logic, data access, background jobs) are packaged and executed as a single unified binary or process.
- **Microservices Architecture**: An architectural style that structures an application as a collection of small, independently deployable services organized around distinct business capabilities, communicating via lightweight APIs (HTTP/gRPC/Kafka).
- **API Gateway**: A single entry-point reverse proxy that sits in front of microservices, routing incoming client traffic, enforcing rate limiting, authenticating JWT tokens, and aggregating responses.
- **CI/CD (Continuous Integration & Continuous Delivery)**: An automated development workflow where developer code commits are constantly tested and packaged into release artifacts (CI), and automatically deployed to staging or production environments (CD).
- **CALMS Framework**: The five pillars of DevOps maturity: **C**ulture (shared responsibility), **A**utomation (eliminating toil), **L**ean (small batch sizes), **M**easurement (observability & SLOs), and **S**haring (cross-functional learning).
- **Immutable Infrastructure**: The cloud-native operations practice where servers, VMs, or containers are never patched or modified in-place; instead, updates are applied by building and deploying entirely new replacement instances.
- **Shift-Left**: Moving critical engineering checks (security scanning, unit testing, performance benchmarking, compliance checks) earlier in the software development lifecycle to catch bugs before they reach production.


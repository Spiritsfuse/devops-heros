# Session 21 - DevOps Final Capstone: TaskBoard (Python)

## Student Information
- **Name:** Dhruv Sharma
- **Enrollment Number (Roll No):** 24BCS10294
- **Session:** Session 21 - Final DevOps Project & Capstone
- **Homework Submission Document:** [Assignment_Readme.md](Assignment_Readme.md)

## 1. What we are building

TaskBoard is a small but realistic SaaS-style project management application:

- React + Vite frontend
- Responsive HTML/JSX + CSS UI
- FastAPI Python backend
- PostgreSQL database
- SQLAlchemy ORM
- Alembic database migrations
- REST APIs
- Pytest automated tests
- Docker containers
- GitHub Actions CI/CD
- Trivy container security scanning
- GitHub Container Registry
- Terraform for AWS infrastructure
- AWS VPC + EKS
- Kubernetes
- Helm
- Ingress
- HPA
- Prometheus + Grafana
- Health/readiness endpoints
- Troubleshooting exercises

The point is not to teach isolated tools. The point is to show how a real application travels from a developer laptop to a monitored Kubernetes environment.

```text
Developer
   |
   v
Git / GitHub
   |
   v
GitHub Actions
   |-- pytest
   |-- frontend build
   |-- Docker build
   |-- Trivy scan
   `-- push images to GHCR
              |
              v
        Terraform
              |
       AWS VPC + EKS
              |
              v
            Helm
              |
      +-------+--------+
      |                |
   Frontend          Backend
    React            FastAPI
      |                |
      +-------> PostgreSQL
              |
       Prometheus
              |
           Grafana
```

---

## 2. Repository structure

```text
session21-devops-capstone-final/
├── frontend/                 # React application and CSS
├── backend/                  # FastAPI application
│   ├── app/                  # API, models, schemas, DB config
│   ├── tests/                # Pytest tests
│   └── alembic/              # DB migrations
├── docker-compose.yml        # Full local stack
├── terraform/                # AWS VPC + EKS infrastructure
├── helm/taskboard/            # Kubernetes package
├── k8s/                      # namespace/bootstrap manifests
├── monitoring/               # Prometheus/Grafana values
├── troubleshooting/          # deliberately broken manifests
├── scripts/                  # load-test helpers
└── .github/workflows/        # CI/CD
```

---

# PART A  -  UNDERSTAND THE APPLICATION

## 3. Frontend

The frontend is intentionally closer to a real SaaS dashboard than a tutorial CRUD page.

It contains:

- dark sidebar
- workspace navigation
- dashboard header
- KPI cards
- task table
- status filters
- priority badges
- activity feed
- pipeline indicator
- create-task modal
- responsive CSS
- loading and backend-error states

The browser calls `/api/tasks` and `/api/tasks/stats`.

The browser does **not** need to know the internal backend hostname. Nginx and Kubernetes Ingress handle routing.

## 4. Backend

FastAPI exposes:

```text
GET    /
GET    /health
GET    /ready
GET    /metrics

GET    /api/tasks
GET    /api/tasks/{id}
POST   /api/tasks
PUT    /api/tasks/{id}
DELETE /api/tasks/{id}
GET    /api/tasks/stats
```

Swagger documentation is available at `/docs` when the backend is running.

### Why `/health`?

A container can be alive while its application is unhealthy. `/health` gives Kubernetes a cheap liveness check.

### Why `/ready`?

Readiness answers a different question: **can this application serve traffic now?** The endpoint verifies database access before returning READY.

### Why `/metrics`?

Prometheus needs machine-readable metrics. The FastAPI Prometheus instrumentator exposes request metrics for monitoring.

---

# PART B  -  RUN IT LOCALLY

## 5. Fastest method: Docker Compose

Requirements:

- Docker Desktop / Docker Engine
- Docker Compose

Run:

```bash
docker compose up --build
```

#### 💡 Command Breakdown (cmd-explained):
- `docker compose up`: Reads `docker-compose.yml`, provisions networking bridges, sets up volumes, and starts all multi-container services (`frontend`, `backend`, `db`) in dependency order.
- `--build`: Forces Docker Compose to rebuild container images from local Dockerfiles even if matching images already exist in the local cache, ensuring code changes are incorporated.
- `-d` (optional flag e.g. `docker compose up -d --build`): "Detached mode". Runs containers in the background, freeing your terminal prompt.
- `docker compose down`: Gracefully stops and deletes active containers, networks, and internal DNS entries created by `up`.
- `-v` (in `docker compose down -v`): "Volumes". Deletes named Docker persistent storage volumes (e.g. `postgres_data`), wiping database state for a completely fresh start.

Open:

```text
http://localhost:3000
```

Backend:

```text
http://localhost:8000/docs
http://localhost:8000/health
http://localhost:8000/metrics
```

Stop:

```bash
docker compose down
```

Delete database volume too:

```bash
docker compose down -v
```

---

## 6. Run backend directly

Requirements:

- Python 3.12+
- PostgreSQL

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Set the database connection:

```bash
export DATABASE_URL='postgresql+psycopg://taskboard:taskboard@localhost:5432/taskboard'
```

Run migrations:

```bash
alembic upgrade head
```

#### 💡 Command Breakdown (cmd-explained):
- `alembic upgrade head`: Executes all unapplied database schema migration scripts in sequence up to the latest revision (`head`), creating tables and indexes in PostgreSQL.

Start FastAPI:

```bash
uvicorn app.main:app --reload --port 8000
```

#### 💡 Command Breakdown (cmd-explained):
- `uvicorn`: High-performance ASGI web server for asynchronous Python web applications.
- `app.main:app`: Looks inside `app/main.py` for the FastAPI instance named `app`.
- `--reload`: Hot-reload flag; automatically detects file changes and restarts worker processes instantly during development.
- `--port 8000`: Binds the server to listen on TCP port 8000.

Test:

```bash
curl http://localhost:8000/health
curl http://localhost:8000/api/tasks
```

Open:

```text
http://localhost:8000/docs
```

---

# PART C  -  TESTING

## 7. Pytest

```bash
cd backend
pytest -q
```

Students should understand why tests happen **before Docker images are pushed**.

```text
Bad code
  ↓
pytest fails
  ↓
Pipeline stops
  ↓
No broken image is promoted
```

This is the first quality gate.

---

# PART D  -  GIT AND GITHUB

## 8. Initialize Git

```bash
git init
git add .
git commit -m "initial TaskBoard application"
git branch -M main
git remote add origin <YOUR_GITHUB_REPO>
git push -u origin main
```

Explain:

- Git = version control
- GitHub = remote collaboration/source platform
- commit = immutable project checkpoint
- branch = isolated line of development
- pull request = controlled change review

---

# PART E  -  DOCKER

## 9. Backend Dockerfile

The backend image:

1. starts from Python
2. installs dependencies
3. copies Alembic
4. copies application code
5. creates a non-root user
6. exposes port 8000
7. runs migrations
8. starts Uvicorn

Build:

```bash
docker build -t taskboard-backend:local ./backend
```

#### 💡 Command Breakdown (cmd-explained):
- `docker build`: Directs Docker Engine to read the `Dockerfile` inside the target directory and assemble a container image layer-by-layer.
- `-t taskboard-backend:local`: Sets a human-readable tag (`<repository>:<tag>`) to identify the resulting image in your local Docker cache.
- `./backend`: The **build context** directory sent to the Docker daemon. All files referenced by `COPY` in the Dockerfile must reside within this context.

Run with a reachable PostgreSQL instance:

```bash
docker run --rm -p 8000:8000 \
  -e DATABASE_URL='postgresql+psycopg://taskboard:taskboard@host.docker.internal:5432/taskboard' \
  taskboard-backend:local
```

#### 💡 Command Breakdown (cmd-explained):
- `docker run`: Creates and starts an active container process from a container image.
- `--rm`: Automatically removes the container filesystem when it terminates or is stopped, keeping your Docker environment clean.
- `-p 8000:8000`: Port forwarding mapping `host_port:container_port`. Exposes FastAPI running on port 8000 inside the container to `http://localhost:8000` on your host.
- `-e DATABASE_URL='...'`: Injects the database connection string as an environment variable into the running container process.
- `host.docker.internal`: Special DNS name resolved by Docker Desktop / WSL2 allowing containers to connect to services running directly on the host machine (e.g., PostgreSQL).
- `taskboard-backend:local`: Target image name and tag to run.

## 10. Frontend Dockerfile

The frontend uses a multi-stage build:

```text
Node
  ↓
npm build
  ↓
static dist/
  ↓
Nginx runtime image
```

This keeps build tooling out of the final runtime image.

Build:

```bash
docker build -t taskboard-frontend:local ./frontend
```

#### 💡 Command Breakdown (cmd-explained):
- `docker build`: Assembles the multi-stage image. Stage 1 executes `npm run build` using Node.js to create the compiled HTML/JS/CSS bundle; Stage 2 copies only the production `/dist` directory into an ultra-slim `nginx:alpine` image.
- `-t taskboard-frontend:local`: Tags the final stage output image.
- `./frontend`: Path to the frontend source folder containing `Dockerfile` and `package.json`.

---

# PART F  -  CI/CD

## 11. GitHub Actions pipeline

The workflow has three conceptual stages:

```text
TEST
 ↓
BUILD + SECURITY SCAN + PUSH
 ↓
DEPLOY
```

### Test job

- checkout
- setup Python
- install requirements
- run pytest
- setup Node
- build React frontend

### Build/scan/push job

- build backend image
- build frontend image
- scan both with Trivy
- push to GHCR

### Deploy job

- install Helm
- configure kubectl
- run `helm upgrade --install`

The image tag is the Git commit SHA.

That means:

```text
commit A → image A
commit B → image B
commit C → image C
```

This gives traceability from production back to source code.

---

# PART G  -  SECURITY SCANNING

## 12. Trivy

The pipeline scans container images for HIGH and CRITICAL vulnerabilities.

A security scanner is not a magic guarantee of security. It is one automated control in the pipeline.

Students should understand:

```text
SAST
Dependency scanning
Secret scanning
Container scanning
Runtime security
```

These are different security layers.

---

# PART H  -  TERRAFORM

## 13. Why Terraform?

Kubernetes only manages workloads. It does not create the AWS network and EKS infrastructure in this project.

Terraform creates:

```text
AWS
 ├── VPC
 ├── public subnets
 ├── private subnets
 ├── NAT gateway
 └── EKS cluster
       └── managed worker nodes
```

Go to Terraform:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

#### 💡 Command Breakdown (cmd-explained):
- `cd terraform`: Switches terminal directory into the Terraform project root where `.tf` configuration files reside.
- `terraform init`: Scans configuration files, downloads required provider plugins (`hashicorp/aws`, etc.) into `.terraform/`, and initializes the backend state storage.
- `terraform plan`: Reads active cloud state, compares it with local HCL definitions, and creates a predictive execution plan detailing additions (`+`), modifications (`~`), or deletions (`-`).
- `terraform apply`: Executes the proposed changes against AWS API, provisioning VPC, subnets, gateways, and EKS managed node groups. Prompts for manual `yes` confirmation before touching live infrastructure.

The default region is `ap-south-1`.

After EKS is created, configure kubectl using the command shown by AWS/Terraform output.

Destroy when finished:

```bash
terraform destroy
```

#### 💡 Command Breakdown (cmd-explained):
- `terraform destroy`: Reverses all provisioned resources tracked in `terraform.tfstate` in topological dependency order (EKS nodes → EKS control plane → subnets → VPC), preventing unexpected cloud billing.

### Important teaching point

Terraform is **Infrastructure as Code**.

Instead of manually clicking:

```text
AWS Console → VPC → Subnet → EKS → Nodes...
```

we describe infrastructure in code and let Terraform reconcile the desired state.

---

# PART I  -  KUBERNETES

## 14. Namespace

```bash
kubectl apply -f k8s/namespace.yaml
```

#### 💡 Command Breakdown (cmd-explained):
- `kubectl apply`: Declarative Kubernetes engine command. Creates or updates resources to match the YAML manifest specifications.
- `-f k8s/namespace.yaml`: Specifies the file path containing the `Kind: Namespace` definition, isolating taskboard resources from `default` or `kube-system`.

A namespace provides logical isolation for the application.

## 15. Helm

Instead of maintaining many manually edited YAML files, Helm turns the Kubernetes deployment into a reusable package.

```bash
helm upgrade --install taskboard ./helm/taskboard \
  --namespace taskboard \
  --create-namespace
```

#### 💡 Command Breakdown (cmd-explained):
- `helm upgrade --install`: Idempotent deployment command. If the release `taskboard` doesn't exist, it performs a fresh installation (`helm install`); if it already exists, it applies upgrades (`helm upgrade`).
- `taskboard`: The unique release name given to this deployment instance.
- `./helm/taskboard`: Path to the chart directory containing `Chart.yaml`, `values.yaml`, and `templates/`.
- `--namespace taskboard`: Specifies target Kubernetes namespace for all templated resources.
- `--create-namespace`: Creates the namespace automatically if it does not already exist in the cluster.

Important Helm concepts:

- Chart
- values
- templates
- release
- upgrade
- rollback

---

# PART J  -  KUBERNETES COMPONENTS

## 16. Deployment

The Deployment manages backend/frontend Pods.

If a Pod dies:

```text
Deployment
   ↓
creates replacement Pod
```

## 17. Service

Pods are ephemeral. A Service provides stable networking.

```text
Frontend → backend Service → backend Pods
```

## 18. PostgreSQL

For the classroom/local Kubernetes demo, PostgreSQL is deployed inside the cluster with a PVC.

For production AWS architecture, students should understand the tradeoff between running PostgreSQL in Kubernetes and using a managed database such as Amazon RDS.

---

# PART K  -  INGRESS

## 19. Ingress

The application has two logical routes:

```text
/taskboard.local/
      ↓
React frontend

/taskboard.local/api
      ↓
FastAPI backend
```

Enable ingress with the dev values:

```bash
helm upgrade --install taskboard ./helm/taskboard \
  -n taskboard \
  -f helm/taskboard/values-dev.yaml
```

#### 💡 Command Breakdown (cmd-explained):
- `helm upgrade --install`: Ensures release `taskboard` is deployed or updated idempotently.
- `-n taskboard`: Shorthand for `--namespace taskboard`.
- `-f helm/taskboard/values-dev.yaml`: Overrides default chart values with environment-specific configurations (e.g., enables `ingress.enabled: true`, sets host to `taskboard.local`, and configures path routing).

Students should understand that an Ingress resource is only configuration. An Ingress Controller must actually implement it.

---

# PART L  -  HPA

## 20. Horizontal Pod Autoscaler

The HPA can scale the backend based on CPU utilization.

```text
low traffic
   ↓
2 Pods

high CPU
   ↓
3 Pods
   ↓
4 Pods
   ↓
...
```

Inspect:

```bash
kubectl get hpa -n taskboard
```

#### 💡 Command Breakdown (cmd-explained):
- `kubectl get hpa`: Retrieves Horizontal Pod Autoscaler controllers in the cluster.
- `-n taskboard`: Restricts output to the `taskboard` namespace.
- **Output Columns Explained**:
  - `REFERENCE`: Target deployment (e.g., `Deployment/taskboard-backend`).
  - `TARGETS`: Current average metric usage vs target threshold (e.g., `12%/50%`).
  - `MINPODS` / `MAXPODS`: Defined scaling boundaries (e.g., 2 to 10).
  - `REPLICAS`: Current number of running Pod copies.

HPA requires resource requests and a metrics provider such as Metrics Server.

A normal health request may not create enough CPU pressure to demonstrate scaling. For a classroom demo, use a controlled load generator and watch the metrics.

---

# PART M  -  MONITORING

## 21. Prometheus

Prometheus collects metrics from the FastAPI `/metrics` endpoint.

The ServiceMonitor tells the Prometheus Operator what to scrape.

## 22. Grafana

Grafana visualizes the collected metrics.

Useful questions:

- How many HTTP requests are arriving?
- Which endpoint is slow?
- Are errors increasing?
- Is the application receiving traffic?
- Is CPU increasing?
- Is HPA scaling?

---

# PART N  -  TROUBLESHOOTING LAB

## 23. Broken image

Apply:

```bash
kubectl apply -f troubleshooting/broken-image.yaml
```

#### 💡 Command Breakdown (cmd-explained):
- `kubectl apply -f troubleshooting/broken-image.yaml`: Deploys an intentionally misconfigured Deployment pointing to a nonexistent Docker image tag (`taskboard-backend:v999-doesnotexist`), triggering an image pull failure.

Then:

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl get events --sort-by=.lastTimestamp
```

#### 💡 Command Breakdown (cmd-explained):
- `kubectl get pods`: Shows high-level status; reveals pods stuck in `ImagePullBackOff` or `ErrImagePull`.
- `kubectl describe pod <pod-name>`: Displays deep pod details. Check the bottom **Events** section to read exact failure messages (e.g., `Failed to pull image: manifest unknown` or `pull access denied`).
- `kubectl get events --sort-by=.lastTimestamp`: Lists all cluster events ordered chronologically, showing exactly when the kubelet failed image pull attempts.

Expected investigation:

```text
ImagePullBackOff
      ↓
describe Pod
      ↓
wrong image/tag
      ↓
fix deployment
```

## 24. Broken Service

Apply:

```bash
kubectl apply -f troubleshooting/broken-service.yaml
```

#### 💡 Command Breakdown (cmd-explained):
- `kubectl apply -f troubleshooting/broken-service.yaml`: Creates a Kubernetes Service whose `spec.selector` has a deliberate typo or mismatch with the Pod's labels (e.g., selector `app: wrong-label` vs pod label `app: taskboard-backend`).

Investigate:

```bash
kubectl get svc
kubectl get endpoints
kubectl get pods --show-labels
```

#### 💡 Command Breakdown (cmd-explained):
- `kubectl get svc`: Verifies Service creation and shows assigned `CLUSTER-IP` and ports.
- `kubectl get endpoints`: Reveals if the Service resolved any backend Pod IPs. If the `ENDPOINTS` column shows `<none>`, selector matching failed.
- `kubectl get pods --show-labels`: Lists running pods along with their exact active label key-value pairs, allowing you to cross-verify against the Service's selector.

The key lesson is that a Service selects Pods using labels.

No matching labels = no endpoints = no traffic.

---

# PART O  -  FINAL DEMO

### 1. Application

Open TaskBoard and create a task.

### 2. API

Open FastAPI Swagger:

```text
/docs
```

Create/read/update/delete a task.

### 3. Database

Show the PostgreSQL `tasks` table.

### 4. Git

Make a small application change and commit it.

### 5. CI

Push to GitHub and show tests running.

### 6. Docker

Show the two images.

### 7. Security

Show Trivy scanning the images.

### 8. Registry

Show the images in GHCR.

### 9. Terraform

Show the AWS infrastructure code.

### 10. Kubernetes

```bash
kubectl get pods -n taskboard
kubectl get svc -n taskboard
```

### 11. Helm

```bash
helm list -n taskboard
```

### 12. Ingress

Open the application through the Ingress hostname.

### 13. HPA

```bash
kubectl get hpa -n taskboard
```

### 14. Monitoring

Show Prometheus and Grafana.

### 15. Failure simulation

Break a Service/image and troubleshoot it live.

---

# FINAL STUDENT PROJECT

Possible domains:

- CRM
- Inventory management
- Appointment booking
- Helpdesk
- Ecommerce administration
- Clinic management
- Restaurant management
- Employee management
- Learning management system

Minimum requirements:

### Application

- frontend
- backend
- PostgreSQL
- minimum 4 REST APIs
- responsive UI

### Engineering

- Git/GitHub
- automated tests
- Docker

### DevOps

- GitHub Actions
- security scan
- container registry
- Terraform
- Kubernetes
- Helm
- Ingress
- HPA
- Prometheus/Grafana

### Final presentation

Each student must demonstrate:

```text
Application
  ↓
Git commit
  ↓
CI pipeline
  ↓
Docker image
  ↓
Security scan
  ↓
Registry
  ↓
Terraform infrastructure
  ↓
Kubernetes deployment
  ↓
Helm
  ↓
Ingress
  ↓
Autoscaling
  ↓
Monitoring
  ↓
Troubleshooting
```

That is the actual objective of Session 21.

---

### 📚 Tech Jargons Demystified:
- **Full-Stack DevOps Lifecycle**: The end-to-end integration of code writing (FastAPI + React), automated schema migrations (Alembic), containerization (Docker multi-stage builds), CI automation (GitHub Actions), vulnerability scanning (Trivy), Cloud IaC provisioning (Terraform on AWS), container orchestration (Kubernetes & Helm), traffic ingress (Ingress Controllers), elasticity (HPA), and full observability (Prometheus & Grafana).
- **Multi-Stage Build**: A Dockerfile pattern using multiple `FROM` instructions where intermediate build dependencies (Node.js SDK, compilation tools, caches) are discarded, and only the minimal production artifacts (compiled HTML/JS) are copied into a lightweight runtime image (Alpine Linux/Nginx), reducing image size by up to 90%.
- **Database Migrations (Alembic)**: Version-controlled schema alterations applied programmatically to the database before the application process starts up, ensuring the PostgreSQL schema perfectly matches the ORM model definitions across all deployment environments.
- **Traceability via Git Commit SHA**: Tagging container images directly with the Git commit hash (`taskboard:c0ffee1`) instead of mutable tags like `latest`. This ensures that any container running in production or cluster can be linked precisely to the exact line of code and author that built it.
- **Service Label Selectors vs Endpoints**: A Kubernetes Service does not directly forward traffic to Pod names; it continuously queries the API Server for Pods matching `spec.selector`. Matching Pods have their internal IPs registered as an `Endpoints` object. If selectors mismatch, the Service has 0 endpoints and traffic drops with connection timeouts.
- **Ingress vs Ingress Controller**: An Ingress resource is merely a declarative configuration document specifying routing rules (e.g., `/api` -> backend, `/` -> frontend). The Ingress Controller (such as ingress-nginx or AWS ALB Controller) is the running reverse-proxy daemon that watches these rules and reconfigures its routing tables dynamically.
- **Metrics Server & HPA**: The Horizontal Pod Autoscaler controller queries the Kubernetes Metrics API (served by Metrics Server) every 15 seconds. If current CPU/memory consumption exceeds the defined target utilization percentage, it scales up the Deployment replica count according to the formula: `desiredReplicas = ceil[currentReplicas * (currentMetric / targetMetric)]`.
- **Shift-Left Security (DevSecOps)**: Introducing automated vulnerability scanning (Trivy for containers, bandit/pip-audit for dependencies) early in the developer pipeline before deployment, preventing insecure images from ever reaching the production cluster.

# Session 20 Screenshots

This directory stores execution and verification screenshots for Monitoring, Observability & GitOps:
- `01-docker-compose-up-ps.png`: Docker Compose stack startup and container process health check for Prometheus and Grafana.
- `02-prometheus-query.png`: Prometheus web UI demonstrating target scraping and metrics query execution.
- `03-grafana-dashboard.png`: Grafana dashboard displaying container and cluster metrics visualization panels.
- `04-argocd-installation.png`: Argo CD namespace creation, CRD installation, and controller pod verification.
- `05-argocd-application-synced.png`: Argo CD web UI showing application `session20-app` in Synced and Healthy status.

---

## Screenshot Execution Commands Breakdown (`cmd-explained`)

### 1. `01-docker-compose-up-ps.png`
```bash
docker compose up -d
docker compose ps
```
#### 💡 Command Breakdown (`cmd-explained`):
- `docker compose up -d`: Spawns Prometheus and Grafana detached (`-d`) in background containers.
- `docker compose ps`: Verifies that `session20-prometheus` and `session20-grafana` are running and bound to host ports.

### 2. `02-prometheus-query.png`
```bash
# Access: http://localhost:9090
```
#### 💡 Command Breakdown (`cmd-explained`):
- Accesses Prometheus Expression Browser to execute PromQL queries and inspect scrape targets.

### 3. `03-grafana-dashboard.png`
```bash
# Access: http://localhost:3000 -> Data Source: http://prometheus:9090
```
#### 💡 Command Breakdown (`cmd-explained`):
- Visualizes time-series metrics collected by Prometheus into interactive charts and operational dashboards.

### 4. `04-argocd-installation.png`
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
#### 💡 Command Breakdown (`cmd-explained`):
- `create namespace argocd`: Provisions dedicated namespace for GitOps controllers.
- `apply -f ...`: Deploys Argo CD CRDs, API server, repo server, and application controller.
- `get pods -n argocd`: Verifies all Argo CD core controller pods reach Running state.
- `port-forward svc/argocd-server`: Exposes the Argo CD dashboard to `https://localhost:8080`.

### 5. `05-argocd-application-synced.png`
```bash
kubectl apply -f 08-mini-project/app/argocd-application.yaml
```
#### 💡 Command Breakdown (`cmd-explained`):
- Submits the Argo CD Application manifest to track the target Git repository path.
- In the Argo CD web UI (`localhost:8080`), verifies that `session20-app` achieves `Synced` (cluster matches Git) and `Healthy` status.


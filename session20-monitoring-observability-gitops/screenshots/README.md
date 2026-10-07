# Session 20 Screenshots

This directory stores execution and verification screenshots for Monitoring, Observability & GitOps:
- `01-metrics-server-top.png`: `kubectl top nodes` and `kubectl top pods` resource utilization.
- `02-prometheus-grafana-dashboard.png`: Grafana dashboard displaying cluster CPU, memory, and network throughput.
- `03-argocd-installation.png`: Argo CD namespace, pods, and web UI login.
- `04-argocd-application-synced.png`: Argo CD application status showing "Synced" and "Healthy".
- `05-gitops-auto-reconciliation.png`: Automated self-healing/reconciliation after making changes in Git.

---

## Screenshot Execution Commands Breakdown (`cmd-explained`)

### 1. `01-metrics-server-top.png`
```bash
kubectl top nodes
kubectl top pods -A
```
#### 💡 Command Breakdown (`cmd-explained`):
- `kubectl top nodes`: Connects to the Kubernetes Metrics Server to pull instantaneous node-level CPU core allocation and memory megabytes.
- `kubectl top pods -A`: Evaluates container-level resource consumption across all cluster namespaces (`-A`), pinpointing noisy neighbor containers.

### 2. `02-prometheus-grafana-dashboard.png`
```bash
docker compose up -d
# Access: http://localhost:3000 (Grafana) -> Data Source: http://prometheus:9090
```
#### 💡 Command Breakdown (`cmd-explained`):
- `docker compose up -d`: Spawns Prometheus and Grafana detached (`-d`) in background containers.
- Demonstrates how metrics collected by Prometheus are graphed into interactive visualization panels inside Grafana dashboards.

### 3. `03-argocd-installation.png`
```bash
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
#### 💡 Command Breakdown (`cmd-explained`):
- `--server-side`: Performs Server-Side Apply to avoid client annotation size overflow when registering Argo CD's large CRDs.
- `port-forward svc/argocd-server 8080:443`: Binds host port 8080 to the Argo CD HTTPS server, allowing browser access to the GitOps control plane.

### 4. `04-argocd-application-synced.png`
```bash
kubectl apply -f app/argocd-application.yaml
kubectl get applications -n argocd
```
#### 💡 Command Breakdown (`cmd-explained`):
- `kubectl apply -f ...`: Tells Argo CD to watch the Git repository path.
- `get applications -n argocd`: Verifies that the application status displays `Synced` (Git commit == Cluster state) and `Healthy` (Pods running).

### 5. `05-gitops-auto-reconciliation.png`
```bash
kubectl scale deployment session20-mini -n session20 --replicas=1
kubectl get deployment -n session20 -w
```
#### 💡 Command Breakdown (`cmd-explained`):
- `scale --replicas=1`: Artificially induces configuration drift by imperatively shrinking the deployment.
- `-w`: Observes Argo CD's active **Self-Healing** loop detecting the deviation and automatically scaling the cluster back to the Git-defined replica count.

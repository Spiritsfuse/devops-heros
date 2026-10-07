# 08 - Session 20 Mini Project

You will combine:

```text
Kubernetes
+
Git
+
GitOps
+
Argo CD
```

The goal:

```text
Git
 |
 | desired state
 v
Argo CD
 |
 | automatic sync
 v
Kubernetes
 |
 v
Application
```

---

# Requirements

Build a small application with:

```text
Namespace
Deployment
Service
Argo CD Application
```

The Deployment should have:

```text
replicas: 2
```

---

# Step 1 - Create Cluster

```bash
kind create cluster --name session20
```

#### 💡 Command Breakdown (`cmd-explained`):
- `kind`: Tool for spinning up Kubernetes nodes inside local Docker containers.
- `create cluster`: Spawns the Docker container control plane and installs Kubernetes core binaries (`kube-apiserver`, `etcd`, `kubelet`).
- `--name session20`: Names the cluster and sets your active `kubectl` context to `kind-session20`.

Check:

```bash
kubectl get nodes
```

#### 💡 Command Breakdown (`cmd-explained`):
- `get nodes`: Contacts the control plane to list all cluster nodes and verify that the status is `Ready`.

Expected:

```text
NAME
session20-control-plane
```

---

# Step 2 - Install Argo CD

```bash
kubectl create namespace argocd
```

#### 💡 Command Breakdown (`cmd-explained`):
- `create namespace argocd`: Creates a dedicated namespace boundary inside Kubernetes to isolate all Argo CD components.

Then:

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### 💡 Command Breakdown (`cmd-explained`):
- `apply -n argocd`: Executes declarative installation of Argo CD inside the `argocd` namespace.
- `-f <url>`: Pulls and applies official upstream installation manifests containing CRDs, RBAC roles, deployments, services, and configmaps.

Wait:

```bash
kubectl get pods -n argocd
```

#### 💡 Command Breakdown (`cmd-explained`):
- `get pods -n argocd`: Lists the running state of Argo CD controller pods (e.g. `repo-server`, `application-controller`, `server`). Wait until all show status `Running`.

---

# Step 3 - Create a Git Repository

Create a repository on GitHub/GitLab/Bitbucket.

Copy these application manifests into the Git repository:

```text
namespace.yaml
deployment.yaml
service.yaml
```

Your Git repository should contain:

```text
app/
|
|-- namespace.yaml
|-- deployment.yaml
|-- service.yaml
```

Keep this teaching project's `argocd-application.yaml` outside the Git `app/` path. The Application object tells Argo CD which repository/path to watch; it should not be rendered as one of the workload manifests from that same path.

---

# Step 4 - Change Repository URL

Open:

```text
app/argocd-application.yaml
```

Replace:

```text
https://github.com/YOUR_USERNAME/YOUR_GITOPS_REPO.git
```

with your actual repository URL.

Commit and push.

---

# Step 5 - Create Application

Apply the Argo CD Application:

```bash
kubectl apply -f app/argocd-application.yaml
```

#### 💡 Command Breakdown (`cmd-explained`):
- `apply -f app/argocd-application.yaml`: Registers the custom `Application` resource with Argo CD's controller, binding the remote Git repo to the local Kubernetes cluster.

Check:

```bash
kubectl get applications -n argocd
```

#### 💡 Command Breakdown (`cmd-explained`):
- `get applications -n argocd`: Checks the GitOps reconciliation engine status.
  - `SYNC STATUS Synced`: Live cluster objects match the git commit tree.
  - `HEALTH STATUS Healthy`: Workload pods are running and ready.

Expected shape:

```text
NAME             SYNC STATUS   HEALTH STATUS
session20-mini   Synced        Healthy
```

---

# Step 6 - Check Kubernetes

```bash
kubectl get all -n session20
```

#### 💡 Command Breakdown (`cmd-explained`):
- `get all`: A composite query fetching all common resources at once: Pods, Services, Deployments, and ReplicaSets.
- `-n session20`: Scopes the query to the application's runtime namespace.

You should see:

```text
deployment.apps/session20-mini
service/session20-mini
pod/session20-mini-xxxxx
pod/session20-mini-yyyyy
```

---

# Step 7 - Make a Git Change

Change in the Git repository:

```yaml
replicas: 2
```

to:

```yaml
replicas: 3
```

Commit:

```bash
git add .
git commit -m "Scale application to three replicas"
git push
```

#### 💡 Command Breakdown (`cmd-explained`):
- `git add .`: Stages the modified `deployment.yaml` with `replicas: 3`.
- `git commit -m "..."`: Records the scale-out intent in git history.
- `git push`: Publishes the commit to GitHub/GitLab, updating the remote Source of Truth.

Watch:

```bash
kubectl get deployment -n session20 -w
```

#### 💡 Command Breakdown (`cmd-explained`):
- `-w` (or `--watch`): Streams deployment status updates continuously. You will watch the `AVAILABLE` and `READY` columns transition dynamically from `2/2` -> `2/3` -> `3/3` as the newly scheduled pod passes its container readiness probe.

Eventually:

```text
READY   3/3
```

The change travelled through:

```text
Git
 |
 v
Argo CD
 |
 v
Kubernetes
```

That is GitOps.

---

# Step 8 - Demonstrate Self-Healing

After Argo CD has synchronized:

```bash
kubectl scale deployment session20-mini \
  -n session20 \
  --replicas=1
```

#### 💡 Command Breakdown (`cmd-explained`):
- `scale`: Imperatively alters the replica count directly on the live Kubernetes cluster.
- `--replicas=1`: Artificially forces the cluster to shrink down to 1 pod.
- **Why we run this**: This simulates **unauthorized manual drift** (e.g. an operator making an emergency manual change in production).
- **The Self-Healing Magic**: Because `selfHeal: true` is enabled in `argocd-application.yaml`, Argo CD constantly compares live cluster state against Git. It immediately catches that live has `1` replica while Git specifies `3`, flags the cluster as `OutOfSync`, and forcefully reconciles the deployment back to `3` replicas!

Check:

```bash
kubectl get deployment -n session20
```

#### 💡 Command Breakdown (`cmd-explained`):
- `get deployment -n session20`: Verifies that Argo CD reversed the manual change, restoring 3 active replicas automatically without human intervention.

Because Git still says:

```text
replicas: 3
```

and self-healing is enabled, Argo CD can reconcile the cluster back toward:

```text
replicas: 3
```

This demonstrates:

```text
Git = desired state
Kubernetes = actual state
Argo CD = reconciler
```

---

# Step 9 - Observe the System

Check application logs:

```bash
kubectl logs deployment/session20-mini -n session20
```

#### 💡 Command Breakdown (`cmd-explained`):
- `logs deployment/session20-mini`: Streams logs from pods backing the deployment to verify healthy request serving and catch any application runtime errors.

Check resources:

```bash
kubectl get pods -n session20
```

#### 💡 Command Breakdown (`cmd-explained`):
- `get pods -n session20`: Verifies all 3 pods are in `Running` state with 0 restarts.

Check Argo CD:

```bash
kubectl get application session20-mini -n argocd
```

#### 💡 Command Breakdown (`cmd-explained`):
- `get application session20-mini -n argocd`: Checks the high-level GitOps custom resource status. Ensures both sync status is `Synced` and health is `Healthy`.

---

# Final Architecture

```text
              Developer
                  |
                  v
               Git Repo
                  |
             desired state
                  |
                  v
              Argo CD
                  |
             reconciliation
                  |
                  v
            Kubernetes
                  |
          +-------+-------+
          |               |
      Deployment        Service
          |
        Pods
```

---

# Final Viva Questions

Explain these in your own words:

```text
1. Monitoring vs Observability
2. Metrics vs Logs vs Traces
3. What is Prometheus?
4. What is Grafana?
5. What is GitOps?
6. Why is Git called the source of truth?
7. What does Argo CD do?
8. What does "desired state" mean?
9. What does "actual state" mean?
10. What is reconciliation?
11. What does self-healing mean in Argo CD?
12. What happens when replicas change from 2 to 3 in Git?
```

---

# Cleanup

Delete the application:

```bash
kubectl delete -f app/argocd-application.yaml
```

#### 💡 Command Breakdown (`cmd-explained`):
- `delete -f app/argocd-application.yaml`: Removes the Argo CD `Application` custom resource. Argo CD automatically prunes and cascades deletion to all managed Kubernetes workloads in `session20`.

Delete the cluster:

```bash
kind delete cluster --name session20
```

#### 💡 Command Breakdown (`cmd-explained`):
- `kind delete cluster`: Destroys the `session20-control-plane` Docker container, freeing host RAM and CPU, and removes the kubeconfig cluster context.

---

# Final Mental Model

Remember only this:

```text
METRICS -> numbers
LOGS    -> events
TRACES  -> request journey

PROMETHEUS -> metrics
GRAFANA    -> dashboards

GIT        -> desired state
ARGO CD    -> reconciliation
KUBERNETES -> actual state
```

And the most important GitOps loop:

```text
        +------------------+
        |       Git        |
        | Desired State    |
        +--------+---------+
                 |
                 v
             Argo CD
                 |
                 v
          Kubernetes
          Actual State
                 |
                 |
                 +-------> Compare
                              |
                              v
                         Reconcile
                              |
                              +----> back to desired state
```

---

### 📚 Tech Jargons Demystified:
- **Declarative GitOps**: Describing the end state in version control rather than executing manual scripts. If a server crashes, the entire stack can be recreated deterministically from Git in minutes.
- **Drift Detection**: The monitoring process by which a controller discovers differences between the declared state in Git and the running environment.
- **Self-Healing**: Automated corrective action taken by the controller to eliminate drift and restore the system to match Git without human intervention.
- **Reconciliation Loop**: The core control cycle: `Observed State` vs `Target State` -> `Actuate changes until Target State == Observed State`.

# GitOps Demo with Argo CD

Argo CD watches this Git repository and keeps your Kubernetes cluster in sync with whatever is committed here.

```
You  →  git push  →  GitHub  →  Argo CD detects change  →  Kubernetes updated automatically
```

---

## Repository Structure

```
gitops-demo/
├── README.md                        ← this file
└── app/
    ├── deployment.yaml              ← your actual application (nginx pods)
    ├── service.yaml                 ← exposes the app inside the cluster
    └── argocd-application.yaml      ← tells Argo CD WHERE to find the above files
```

### What is what?

| File | What it is | Who applies it |
|------|-----------|----------------|
| `app/deployment.yaml` | Your **actual application** — nginx containers | Argo CD (automatically from Git) |
| `app/service.yaml` | Makes the app reachable inside the cluster | Argo CD (automatically from Git) |
| `app/argocd-application.yaml` | Argo CD config that points at this repo | **You apply this once manually** |

> **The key confusion point:** You never directly apply `deployment.yaml` or `service.yaml` with kubectl.
> Instead, you apply `argocd-application.yaml` **once**, and then Argo CD reads the `app/` folder
> from GitHub and deploys everything automatically — now and on every future `git push`.

---

## Prerequisites

| Tool | Install |
|------|---------|
| Docker Desktop | https://www.docker.com/products/docker-desktop/ |
| kind | https://kind.sigs.k8s.io/docs/user/quick-start/#installation |
| kubectl | https://kubernetes.io/docs/tasks/tools/ |

---

## Step 1 — Create a Local Kubernetes Cluster

```bash
kind create cluster --name session20
```

#### 💡 Command Breakdown (`cmd-explained`):
- `kind`: Tool for provisioning local multi-node or single-node Kubernetes clusters inside Docker containers.
- `create cluster`: Spawns a dedicated Docker container running a complete Kubernetes node with containerd runtime.
- `--name session20`: Assigns `session20` as the cluster identifier and switches your current `kubectl` context to `kind-session20`.

Verify it is running:

```bash
kubectl cluster-info
kubectl get nodes
```

#### 💡 Command Breakdown (`cmd-explained`):
- `cluster-info`: Displays Kubernetes control plane master URL and CoreDNS service endpoints, verifying network connectivity to the API server.
- `get nodes`: Lists the machines/containers participating in the cluster and confirms their readiness status (`Ready`).

Expected:

```
NAME                     STATUS   ROLES
session20-control-plane  Ready    control-plane
```

---

## Step 2 — Install Argo CD

```bash
kubectl create namespace argocd

kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

```

#### 💡 Command Breakdown (`cmd-explained`):
- `create namespace argocd`: Creates an isolated logical workspace (`argocd`) inside the cluster to host Argo CD system services.
- `apply -n argocd`: Directs the installation manifests to deploy inside the `argocd` namespace.
- `--server-side`: Uses Kubernetes **Server-Side Apply (SSA)** instead of client-side apply. Argo CD ships with very large Custom Resource Definitions (CRDs) like ApplicationSets. Standard client-side apply tries to store the entire YAML manifest inside the `kubectl.kubernetes.io/last-applied-configuration` annotation, which exceeds Kubernetes' 262,144-byte (256 KB) annotation size limit and fails! Server-Side Apply shifts calculation to the `kube-apiserver` and tracks field management without annotation bloat.
- `--force-conflicts`: Forces the API server to grant field ownership to this apply operation, resolving any schema conflicts.
- `-f <url>`: Streams and applies the official remote upstream manifests directly from the official GitHub URL.

Wait for all pods to reach `Running` (takes 2–5 min, images are large):

```bash
kubectl get pods -n argocd -w
```

#### 💡 Command Breakdown (`cmd-explained`):
- `get pods -n argocd`: Queries the status of all pods running in the `argocd` namespace.
- `-w` (or `--watch`): Opens a persistent event stream from the API server. Instead of exiting immediately, it keeps running in the terminal and prints an updated line every time a pod transitions between lifecycle phases (e.g., `Pending` -> `ContainerCreating` -> `Running`).

Expected output when ready:

```
argocd-application-controller-0                    1/1  Running
argocd-applicationset-controller-...               1/1  Running
argocd-dex-server-...                              1/1  Running
argocd-notifications-controller-...               1/1  Running
argocd-redis-...                                   1/1  Running
argocd-repo-server-...                             1/1  Running
argocd-server-...                                  1/1  Running
```

Press `Ctrl+C` when all show `Running`.

---

## Step 3 — Access the Argo CD UI

Open a **new terminal tab** and run (keep it open):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

#### 💡 Command Breakdown (`cmd-explained`):
- `port-forward`: Establishes a local TCP proxy tunnel from your host machine into the Kubernetes cluster network.
- `svc/argocd-server`: Targets the Kubernetes Service object fronting the Argo CD web dashboard and API.
- `-n argocd`: Names the target namespace containing the service.
- `8080:443`: Format is `<local-port>:<cluster-service-port>`. Forwards traffic received on `localhost:8080` of your browser directly to port `443` (HTTPS) of the Argo CD server inside Kubernetes.

Open your browser at:

```
https://localhost:8080
```

> Your browser shows a certificate warning — click **Advanced → Proceed**. This is normal for local labs.

### Get the admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

#### 💡 Command Breakdown (`cmd-explained`):
- `get secret argocd-initial-admin-secret`: Retrieves the Kubernetes Secret object automatically generated during Argo CD's initial installation.
- `-o jsonpath="{.data.password}"`: Extracts only the raw base64-encoded string stored inside the `password` key of the Secret.
- `| base64 -d`: Pipes (`|`) the encoded string to the Unix `base64` utility with the `-d` (`--decode`) flag to decode it into plain human-readable ASCII text.
- `&& echo`: If decoding succeeds, prints a trailing newline character so your command prompt doesn't get glued to the password text on screen.

Login with:
- **Username:** `admin`
- **Password:** output of the command above

---

## Step 4 — Register Your App with Argo CD (One-time Step)

This is the **single manual step** you do once. It tells Argo CD:
*"Watch the `app/` folder in this GitHub repo and deploy whatever is there into the `session20` namespace."*

> [!IMPORTANT]
> ### 🔍 Which Git Repository Does Argo CD Sync?
> Argo CD runs **inside Kubernetes** and does **not** read files from your local hard drive. It continuously polls a remote **GitHub repository**.
>
> You have two options for which repository to use:
>
> #### Option A — Dedicated GitOps Repo (Recommended & Industry Standard)
> Keep your infrastructure manifests separated in their own repo (e.g., `https://github.com/Spiritsfuse/gitops-demo.git`).
>
> **Structure of `gitops-demo` on GitHub:**
> ```text
> gitops-demo/
> └── app/
>     ├── deployment.yaml
>     └── service.yaml
> ```
> *(Note: Do NOT commit `argocd-application.yaml` into `app/`. That file is an admin configuration applied once locally via `kubectl`.)*
>
> In `app/argocd-application.yaml`:
> ```yaml
> source:
>   repoURL: https://github.com/Spiritsfuse/gitops-demo.git
>   targetRevision: main
>   path: app
> ```
>
> #### Option B — Direct Monorepo Sync (Using this `devops-heros` repo)
> If you don't want to maintain a separate repo, you can point Argo CD directly to this `devops-heros` repository:
>
> In `app/argocd-application.yaml`:
> ```yaml
> source:
>   repoURL: https://github.com/Spiritsfuse/devops-heros.git
>   targetRevision: main
>   path: session20-monitoring-observability-gitops/07-argocd/app
> ```
> *(Note: If you use Option B, your commit & push commands in Step 7 will be made directly to `devops-heros`.)*

---

### Apply the Application Manifest

```bash
kubectl apply -f app/argocd-application.yaml
```

#### 💡 Command Breakdown (`cmd-explained`):
- `apply -f app/argocd-application.yaml`: Creates an `Application` resource in Kubernetes (defined by Argo CD's Custom Resource Definition `argoproj.io/v1alpha1`).
- This binds the Git repository source directly to the destination cluster and namespace.

### What this file does

```yaml
# app/argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: session20-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/Spiritsfuse/gitops-demo.git   # ← YOUR GitHub repository
    targetRevision: main
    path: app          # ← Argo CD reads deployment.yaml + service.yaml from here

  destination:
    server: https://kubernetes.default.svc
    namespace: session20   # ← deploys into this namespace in your cluster

  syncPolicy:
    automated:
      prune: true        # ← deletes k8s resources if you remove files from Git
      selfHeal: true     # ← reverts manual kubectl changes back to what Git says
    syncOptions:
      - CreateNamespace=true   # ← creates the session20 namespace automatically
```

After applying, Argo CD will:
1. Read `deployment.yaml` and `service.yaml` from GitHub
2. Create the `session20` namespace
3. Deploy your nginx application


---

## Step 5 — Verify Your Application is Running

Check that Argo CD deployed your app:

```bash
# See the pods (your actual nginx containers)
kubectl get pods -n session20

# See the deployment
kubectl get deployment session20-gitops-app -n session20

# See what Argo CD thinks
kubectl get applications -n argocd
```

#### 💡 Command Breakdown (`cmd-explained`):
- `get pods -n session20`: Verifies that Argo CD successfully read the Git repo and created the workload pods inside the isolated `session20` namespace.
- `get deployment session20-gitops-app -n session20`: Checks the deployment status to ensure the desired replica count matches live pods.
- `get applications -n argocd`: Queries the Argo CD controller for the health and synchronization status of registered applications.
  - `SYNC STATUS Synced`: The Kubernetes cluster matches the Git commit hash exactly.
  - `HEALTH STATUS Healthy`: All pods and services are passing readiness probes without crashes.

Expected:

```
# pods
NAME                                    READY   STATUS
session20-gitops-app-...               1/1     Running
session20-gitops-app-...               1/1     Running
... (5 total)

# application
NAME            SYNC STATUS   HEALTH STATUS
session20-app   Synced        Healthy
```

---

## Step 6 — Open Your Actual Application in a Browser

Your app is nginx running inside Kubernetes. To access it locally:

Open a **new terminal tab** and run (keep it open):

```bash
kubectl port-forward svc/session20-gitops-app -n session20 9090:80
```

#### 💡 Command Breakdown (`cmd-explained`):
- `port-forward`: Binds your machine's loopback interface directly to a Kubernetes Service.
- `svc/session20-gitops-app`: Specifies the service routing traffic to the backend nginx pods.
- `9090:80`: Listens on `localhost:9090` on your host PC and forwards raw TCP packets to port `80` (HTTP) of the nginx service.

Then open:

```
http://localhost:9090
```

You will see the **nginx welcome page** — this is your actual application running in the cluster.

```
Two port-forwards you need open simultaneously:
  Terminal 1: kubectl port-forward svc/argocd-server -n argocd 8080:443    → Argo CD UI
  Terminal 2: kubectl port-forward svc/session20-gitops-app -n session20 9090:80 → Your app
```

---

## Step 7 — GitOps in Action: Scale by Committing to Git

This is the whole point of GitOps. You **do not** run `kubectl scale`.
You change a file, push it to Git, and Argo CD syncs the cluster automatically.

---

### Scale down to 2 replicas

**1. Edit `app/deployment.yaml`:**

```yaml
# Change this:
replicas: 5

# To this:
replicas: 2
```

**2. Commit and push:**

```bash
git add app/deployment.yaml
git commit -m "Scale down to 2 replicas"
git push
```

#### 💡 Command Breakdown (`cmd-explained`):
- `git add app/deployment.yaml`: Stages the scaled replica configuration.
- `git commit -m "..."`: Records the infrastructure revision with a descriptive audit log message.
- `git push`: Transmits the commit to the remote GitHub repository where Argo CD is listening.

**3. Watch Argo CD sync (within ~30 seconds):**

```bash
kubectl get pods -n session20 -w
```

#### 💡 Command Breakdown (`cmd-explained`):
- `-w`: Streams pod termination events live. As Argo CD detects the git commit, Kubernetes gracefully sends `SIGTERM` to the 3 extra pods and terminates them down to 2.

You will see pods terminating until only 2 remain.

**4. Verify:**

```bash
kubectl get deployment session20-gitops-app -n session20
```

```
NAME                   READY   UP-TO-DATE   AVAILABLE
session20-gitops-app   2/2     2            2
```

---

### Scale up to 3 replicas

**1. Edit `app/deployment.yaml`:**

```yaml
replicas: 3
```

**2. Commit and push:**

```bash
git add app/deployment.yaml
git commit -m "Scale up to 3 replicas"
git push
```

**3. Verify:**

```bash
kubectl get deployment session20-gitops-app -n session20
```

```
NAME                   READY   UP-TO-DATE   AVAILABLE
session20-gitops-app   3/3     3            3
```

---

## How Auto-Sync Works

```
┌─────────────────────────────────────────────────────────────┐
│  You edit app/deployment.yaml and git push                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
                   GitHub Repository
             (e.g., Spiritsfuse/gitops-demo)
                           │
              Argo CD polls every 3 minutes
                           │
                           ▼
            ┌──────────────────────────┐
            │        Argo CD           │
            │  Sees Git changed        │
            │  Compares desired state  │
            │  vs current cluster      │
            │  Applies the difference  │
            └──────────────┬───────────┘
                           │
                           ▼
            ┌──────────────────────────┐
            │  Kubernetes (kind)       │
            │  namespace: session20    │
            │  session20-gitops-app    │
            │  (nginx pods updated)    │
            └──────────────────────────┘
```

---

## Quick Reference — Commit Message Conventions

```bash
# Scaling changes
git commit -m "Scale to 2 replicas"
git commit -m "Scale up to 5 replicas for load testing"

# Image updates
git commit -m "Bump nginx to 1.28-alpine"

# Config changes
git commit -m "Add resource limits to deployment"
```

---

## Useful Commands

```bash
# ─── Argo CD ───────────────────────────────────────────────
kubectl get pods -n argocd                          # see Argo CD pods
kubectl get applications -n argocd                  # see sync status

# ─── Your Application ──────────────────────────────────────
kubectl get pods -n session20                       # see nginx pods
kubectl get deployment session20-gitops-app -n session20  # see replica count
kubectl get svc -n session20                        # see services

# ─── Port Forwards ─────────────────────────────────────────
# Argo CD UI   → https://localhost:8080
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Your app     → http://localhost:9090
kubectl port-forward svc/session20-gitops-app -n session20 9090:80

# ─── Get Admin Password ────────────────────────────────────
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## Clean Up

```bash
# Remove the Argo CD application (also removes your app from the cluster)
kubectl delete -f app/argocd-application.yaml

# Delete the local Kubernetes cluster entirely
kind delete cluster --name session20
```

#### 💡 Command Breakdown (`cmd-explained`):
- `kubectl delete -f app/argocd-application.yaml`:
  - Deletes the `Application` custom resource from Argo CD.
  - Because `prune: true` was configured, Argo CD's garbage collection automatically cascades and cleans up all nginx pods, deployments, and services it previously created in the `session20` namespace.
- `kind delete cluster --name session20`:
  - Destroys the Docker container backing the control plane, wipes ephemeral etcd storage, and cleans up your local `~/.kube/config` context.

---

## Troubleshooting

### My app is not showing up in the `session20` namespace

Make sure you applied the Argo CD Application:

```bash
kubectl get applications -n argocd
```

If the list is empty:

```bash
kubectl apply -f app/argocd-application.yaml
```

### Argo CD shows `OutOfSync` and is not syncing automatically

Check that `automated` is set in `app/argocd-application.yaml`:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

Or manually trigger a sync:

```bash
kubectl patch application session20-app -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

#### 💡 Command Breakdown (`cmd-explained`):
- `patch`: Imperatively updates specific fields of a live API object without requiring a full YAML manifest edit.
- `application session20-app -n argocd`: Identifies the target custom resource in the `argocd` namespace.
- `--type merge`: Specifies the **JSON Merge Patch** strategy (RFC 7386), merging the patch payload directly into the resource's JSON representation.
- `-p '{"operation":{"sync":{}}}'`: The JSON patch payload that injects a manual sync operation flag, causing the controller to immediately reconcile with Git without waiting for the next polling interval.

### `argocd-applicationset-controller` in CrashLoopBackOff

**Error:** `no matches for kind "ApplicationSet" in version "argoproj.io/v1alpha1"`

**Fix:** Re-apply the full install to restore the missing CRD:

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl rollout restart deployment argocd-applicationset-controller -n argocd
```

#### 💡 Command Breakdown (`cmd-explained`):
- `rollout restart`: Triggers a step-by-step rolling restart of the deployment's pods by injecting a `kubectl.kubernetes.io/restartedAt` timestamp into the pod template metadata.
- This forces the deployment controller to spin up new healthy pods against the newly installed CRD before terminating the old crashing pods, avoiding service downtime.

---

### 📚 Tech Jargons Demystified:
- **CRD (Custom Resource Definition)**: A Kubernetes extension mechanism that introduces custom API object types (like `Application` or `ApplicationSet`) beyond core types like Pod and Service.
- **Self-Healing (`selfHeal: true`)**: If someone bypasses Git and modifies a live cluster object directly (e.g., manually scaling pods via `kubectl scale`), Argo CD detects the divergence and immediately overrides the cluster back to the state declared in Git.
- **Pruning (`prune: true`)**: If you delete a manifest file (e.g. `service.yaml`) from the Git repository, Argo CD automatically detects that the resource is no longer desired and removes it from the Kubernetes cluster.
- **Port-Forwarding Tunnel**: A direct, authenticated bidirectional TCP stream between your local loopback interface and a pod/service port routed through the Kubernetes API server proxy.

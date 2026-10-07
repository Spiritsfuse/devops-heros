# 05 - Introduction to GitOps

GitOps is a way of managing infrastructure and application deployment using Git.

The central idea:

> Git describes the desired state of the system.

---

# Traditional Deployment

A developer might do:

```bash
kubectl apply -f deployment.yaml
```

#### 💡 Command Breakdown (`cmd-explained`):
- `kubectl`: The client CLI executing on the developer's laptop.
- `apply`: Pushes configuration imperatively to the cluster API.
- `-f deployment.yaml`: Targets a local file on the developer's workstation.
- **The Problem with Traditional Deployment**:
  1. Requires developers to have direct admin credentials (`kubeconfig`) to the production cluster, introducing security risks.
  2. If an engineer manually tweaks the deployment (`kubectl edit` or `kubectl scale`), no history or audit trail is recorded.
  3. Risk of **configuration drift**—what is running in the cluster no longer matches what is committed in Git.

Directly:

```text
Developer
    |
    v
kubectl
    |
    v
Kubernetes
```

---

# GitOps Deployment

With GitOps:

```text
Developer
    |
    v
Git
    |
    v
Argo CD
    |
    v
Kubernetes
```

The developer changes Git.

Argo CD notices.

Argo CD synchronizes the cluster.

---

# Why Git?

Git gives us:

```text
History
Review
Diffs
Rollback point
Collaboration
Audit trail
```

Suppose:

```text
Monday:
replicas = 2

Tuesday:
replicas = 5

Wednesday:
replicas = 2
```

Git records these changes.

---

# Desired State

Suppose Git contains:

```yaml
spec:
  replicas: 3
```

This means:

> "I want 3 replicas."

The cluster might currently have:

```text
2 replicas
```

GitOps controller sees:

```text
Desired = 3
Actual  = 2
```

It works toward:

```text
Actual = 3
```

---

# Demo Manifest

Look at:

```text
app/deployment.yaml
```

It says:

```yaml
replicas: 2
```

Apply it manually once just to understand Kubernetes:

```bash
kubectl apply -f app/
```

#### 💡 Command Breakdown (`cmd-explained`):
- `kubectl apply`: Submits the resource definitions to the Kubernetes API server.
- `-f app/`: Recursively processes all YAML manifest files found in the `app/` folder (such as `deployment.yaml` and `service.yaml`) in a single batch call.
- **Theory Connection**: Creates the initial baseline workload in Kubernetes so we can observe how controllers manage pods.

Check:

```bash
kubectl get deployment
```

#### 💡 Command Breakdown (`cmd-explained`):
- `get deployment`: Queries the cluster for Deployment controllers in the current namespace.
- **Output Columns Explained**:
  - `READY 2/2`: 2 pods out of 2 requested are actively passing readiness probes.
  - `UP-TO-DATE 2`: 2 pods have been updated to achieve the latest pod template specification.
  - `AVAILABLE 2`: 2 pods are currently available to serve client traffic.

Expected shape:

```text
NAME             READY   UP-TO-DATE   AVAILABLE
session20-app    2/2     2            2
```

---

# Important

In real GitOps:

```text
Git
  |
  v
Controller
  |
  v
Cluster
```

You generally do not make routine production changes by manually editing the cluster.

You change the Git configuration.

---

# Practice

Explain:

```text
Git = desired state
Cluster = actual state
Argo CD = keeps them synchronized
```

---

### 📚 Tech Jargons Demystified:
- **Push-based CI/CD**: A pipeline (e.g., Jenkins, GitHub Actions) that stores cluster credentials and directly runs `kubectl apply` against the cluster. If the pipeline fails or is bypassed, the cluster state drifts.
- **Pull-based GitOps**: An in-cluster operator (like Argo CD) that periodically pulls desired state from Git. The cluster pulls changes inward, so no external system needs cluster admin credentials.
- **Configuration Drift**: The discrepancy when the live environment (actual state) differs from what is declared in Git (desired state), caused by emergency manual edits or out-of-band changes.
- **Reconciliation Loop**: The infinite background control loop executed by GitOps agents: `Observe -> Compare -> Reconcile (heal)`.
- **Single Source of Truth (SSOT)**: The architectural principle that the Git repository is the sole authoritative definition of the entire infrastructure and application stack.

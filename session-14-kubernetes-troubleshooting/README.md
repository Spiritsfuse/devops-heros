# Kubernetes Troubleshooting

The goal is to learn how to answer:

> "My Kubernetes application is not working. How do I find out why?"

---

## Topics

We will cover:

* `kubectl get`
* `kubectl describe`
* `kubectl logs`
* `kubectl exec`
* `Events`
* `CrashLoopBackOff`
* `ImagePullBackOff`
* `Pending Pods`
* `Service Troubleshooting`
* `DNS Troubleshooting`

---

## Folder Structure

```text
01-kubectl-get
02-kubectl-describe
03-kubectl-logs
04-kubectl-exec
05-events
06-crashloopbackoff
07-imagepullbackoff
08-pending-pod
09-service-dns
mini-project
```

Each folder contains a small practical example.

---

## Troubleshooting Mindset

When an application is not working, don't randomly run commands.

Follow a process:

```text
1. Observe
      │
      ▼
2. Identify the resource
      │
      ▼
3. Check status
      │
      ▼
4. Check details
      │
      ▼
5. Check events
      │
      ▼
6. Check logs
      │
      ▼
7. Enter container if possible
      │
      ▼
8. Test connectivity
      │
      ▼
9. Find root cause
      │
      ▼
10. Fix
      │
      ▼
11. Verify
```

---

## The Five Commands

### 1. `kubectl get`

Use it for a quick view.

```bash
kubectl get pods
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pods`: Queries the API server for high-level state of all pods in the active namespace. Key triage columns: `READY` (e.g. `0/1`), `STATUS` (`CrashLoopBackOff`, `Pending`, `Running`), and `RESTARTS` (frequent restarts indicate an unstable process).

**Question:**
> "What is happening?"

---

### 2. `kubectl describe`

Use it for detailed information.

```bash
kubectl describe pod <pod-name>
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl describe pod <name>`: Fetches full object schema and recent lifecycle Events recorded by the kubelet and scheduler. Crucial for diagnosing why a pod cannot start before container logs even exist.

**Question:**
> "What details can explain the problem?"

---

### 3. `kubectl logs`

Use it to see application output.

```bash
kubectl logs <pod-name>
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl logs <pod-name>`: Fetches stdout and stderr streams from the container runtime. Reveals unhandled exceptions, missing database connections, bad environment variables, or segmentation faults.

**Question:**
> "What is the application saying?"

---

### 4. `kubectl exec`

Use it to run commands inside a running container.

```bash
kubectl exec -it <pod-name> -- sh
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl exec -it <pod-name> -- sh`: Spawns an interactive shell inside the container to inspect local disk filesystem permissions, test network routes, or verify environment variables.

**Question:**
> "What can I see from inside the container?"

---

### 5. `Events`

Use Events to understand what Kubernetes tried to do.

```bash
kubectl get events
```

or:

```bash
kubectl describe pod <pod-name>
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get events`: Shows cluster-wide chronological event stream (Image pulling, node assignment, volume mounting, probe failures, OOM kills). Add `--sort-by='.metadata.creationTimestamp'` for strict temporal ordering.

**Question:**
> "What did Kubernetes try, and what happened?"

---

## Common Kubernetes Problems

### CrashLoopBackOff

```text
Container starts
      │
      ▼
Application crashes
      │
      ▼
Container restarts
      │
      ▼
Crash again
      │
      ▼
CrashLoopBackOff
```

**Check:**

```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl logs <pod-name> --previous`: Essential flag `--previous` (`-p`). If the current container is continuously crashing or restarting, regular logs may be empty or only show initialization; `--previous` retrieves the crash dump from the *prior terminated instance*.

---

### ImagePullBackOff

```text
Kubernetes
    │
    ▼
Needs image
    │
    ▼
Pull fails
    │
    ▼
Retries
    │
    ▼
ImagePullBackOff
```

**Check:**

```bash
kubectl describe pod <pod-name>
```

#### 💡 Command Breakdown (cmd-explained):
* `describe pod <name>`: Scroll down to `Events:`. Identifies the exact pull failure reason: `404 Not Found` (wrong image/tag), `401 Unauthorized` (missing `imagePullSecrets`), or DNS timeout reaching the registry.

Look at Events.

---

### Pending Pod

```text
Pod created
    │
    ▼
Scheduler tries to find a node
    │
    ▼
Cannot schedule
    │
    ▼
Pending
```

**Check:**

```bash
kubectl describe pod <pod-name>
```

#### 💡 Command Breakdown (cmd-explained):
* `describe pod <name>`: If a pod is `Pending`, it has never been assigned to a node. The `Events` section will display `FailedScheduling` (e.g. `0/3 nodes are available: 3 Insufficient cpu`, or node taint mismatch).

Look at Events.

---

### Service Problem

**Check:**

```bash
kubectl get pods
kubectl get service
kubectl describe service <service-name>
kubectl get endpoints <service-name>
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get endpoints <service-name>`: The ultimate litmus test for service connectivity. If `ENDPOINTS` is `<none>`, the service `selector` does not match the pod `labels`, or the pod readiness probe is failing!

Most importantly:

```text
Pod labels
    │
    ▼
Service selector
    │
    ▼
Endpoints
```

They need to match correctly.

---

### DNS Problem

Test from inside a Pod:

```bash
nslookup <service-name>
```

Check CoreDNS:

```bash
kubectl get pods -n kube-system
```

Check CoreDNS logs:

```bash
kubectl logs -n kube-system -l k8s-app=kube-dns
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl logs -n kube-system -l k8s-app=kube-dns`: Inspects CoreDNS pod logs for upstream timeouts, forwarding loops, or memory exhaustion.

---

## Golden Troubleshooting Flow

Students should remember this:

```text
              PROBLEM
                 │
                 ▼
            kubectl get
                 │
                 ▼
           What is the status?
                 │
                 ▼
         kubectl describe
                 │
                 ▼
              Events
                 │
                 ▼
           kubectl logs
                 │
                 ▼
           kubectl exec
                 │
                 ▼
           Test connectivity
                 │
                 ▼
            Find root cause
                 │
                 ▼
                FIX
                 │
                 ▼
              VERIFY
```

---

## Learning

* Check Kubernetes resource status
* Inspect detailed resource information
* Read application logs
* Execute commands inside containers
* Understand Kubernetes Events
* Troubleshoot `CrashLoopBackOff`
* Troubleshoot `ImagePullBackOff`
* Troubleshoot `Pending` Pods
* Troubleshoot Services
* Test Kubernetes DNS
* Identify root causes instead of guessing

---

### 📚 Tech Jargons Demystified:
* **CrashLoopBackOff:** A state where a container repeatedly starts, crashes (exits with non-zero status), and Kubernetes backs off exponential restart delays (10s, 20s, 40s... up to 5 minutes) to avoid CPU thrashing on the node.
* **ImagePullBackOff / ErrImagePull:**
  * `ErrImagePull`: Initial failure to download the container image.
  * `ImagePullBackOff`: Kubernetes enters an exponential backoff waiting loop before retrying the image pull.
* **Pending Pod:** The pod has been accepted by the API server but has not been scheduled onto a worker node, usually due to lack of CPU/memory resources, unfulfilled PVCs, or unmatched node selectors/taints.
* **Endpoints `<none>`:** Occurs when a Service's `spec.selector` fails to match the labels of any running Pods, or matching pods are failing their readiness probes, resulting in HTTP 503 or connection refused errors.
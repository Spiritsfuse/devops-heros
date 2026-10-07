# `CrashLoopBackOff`

```text
See problem
     │
     ▼
Find reason
     │
     ▼
Fix problem
```

---

## 1. Create The Broken Pod

Run:

```bash
kubectl apply -f broken-pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f broken-pod.yaml`: Deploys a deliberately faulty pod whose entrypoint runs `exit 1`, causing an immediate process crash.

Check:

```bash
kubectl get pod crash-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pod crash-demo`: Observes the pod status cycle through `Running` -> `Error` -> `CrashLoopBackOff` with `RESTARTS` incrementing with each attempt.

You may see:

```text
NAME         READY   STATUS             RESTARTS
crash-demo   0/1     CrashLoopBackOff   3
```

*(The restart count may increase.)*

---

## 2. What Does `CrashLoopBackOff` Mean?

It means the container is repeatedly starting and failing.

Simple flow:

```text
Container starts
      │
      ▼
Application crashes
      │
      ▼
Container stops
      │
      ▼
Kubernetes restarts it
      │
      ▼
Application crashes again
      │
      ▼
Kubernetes waits
      │
      ▼
Tries again
```

The waiting time is part of Kubernetes' backoff behavior.

---

## 3. First Troubleshooting Command

Run:

```bash
kubectl describe pod crash-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl describe pod crash-demo`: Inspects the `Last State:` block under `Containers:`. Shows `Exit Code: 1`, `Terminated: Reason: Error`, and event warnings indicating `Back-off restarting failed container`.

Look at:
* **State**
* **Last State**
* **Restart Count**
* **Events**

---

## 4. Check Logs

Run:

```bash
kubectl logs crash-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl logs crash-demo`: Extracts the crash output from stdout/stderr, exposing what the application printed right before dying.

Expected output:

```text
Application starting...
Something went wrong!
```

This tells us the application itself exited with an error.

---

## 5. Check Previous Logs

Because the container is restarting, also try:

```bash
kubectl logs crash-demo --previous
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl logs crash-demo --previous`: Retrieves stdout/stderr from the terminated container execution preceding the current backoff delay cycle.

This is extremely useful when the current container has already restarted.

---

## 6. Find The Problem

Look at the YAML:

```yaml
exit 1
```

Exit code 1 means the command failed. So the application is crashing because we explicitly told it to exit with an error.

---

## 7. Fix The Pod

First delete the broken Pod:

```bash
kubectl delete pod crash-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl delete pod crash-demo`: Removes the crashed pod object, resetting the backoff delay counter.

Create the fixed version:

```bash
kubectl apply -f fixed-pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f fixed-pod.yaml`: Deploys the corrected pod whose container process runs continuously without exiting.

Check:

```bash
kubectl get pod crash-demo
```

Expected output:

```text
NAME         READY   STATUS
crash-demo   1/1     Running
```

---

## 8. Check Logs Again

```bash
kubectl logs crash-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl logs crash-demo`: Verifies that the fixed application logs show healthy ongoing operation.

Expected output:

```text
Application starting...
Application is healthy
```

---

## Troubleshooting Flow

Remember this flow:

```text
kubectl get pod
       │
       ▼
    STATUS?
       │
       ▼
CrashLoopBackOff
       │
       ▼
kubectl describe pod
       │
       ▼
  kubectl logs
       │
       ▼
kubectl logs --previous
       │
       ▼
Find root cause
       │
       ▼
      Fix
```

---

## Key Learning

`CrashLoopBackOff` is a symptom, not the actual root cause.

The actual reason could be:
* Application error
* Wrong command
* Missing environment variable
* Configuration problem
* Failed dependency
* Bad probe
* Permission problem

Always investigate instead of simply restarting the Pod.

---

## Reference

* **Kubernetes Pod debugging documentation:**  
  https://kubernetes.io/docs/tasks/debug/debug-application/
* **Kubernetes Pod States:**  
  https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase

---

### 📚 Tech Jargons Demystified:
* **CrashLoopBackOff:** A state where kubelet restarts a failing container with exponentially increasing delay periods ($10\text{s}, 20\text{s}, 40\text{s}, 80\text{s}, 160\text{s}$, capped at $300\text{s}$ / 5 minutes) to protect node CPU and etcd from being overwhelmed.
* **RestartPolicy:** Pod configuration setting:
  * `Always` (default for Deployments): Restarts the container whenever it stops, regardless of exit code.
  * `OnFailure`: Restarts only if the container exits with a non-zero exit code.
  * `Never`: Never restarts the container (standard for Jobs).
* **OOMKilled:** Out Of Memory Kill. Occurs when a container exceeds the memory boundary declared in `resources.limits.memory`. Linux kernel cgroups kill the container immediately with exit code 137.

# `kubectl logs`

```bash
kubectl logs
```

Think of logs as:

> "Let me see what the application itself is saying."

Kubernetes commonly exposes container output written to standard output and standard error through `kubectl logs`.

---

## 1. Create the Pod

```bash
kubectl apply -f pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f pod.yaml`: Deploys the logging demo pod which writes status messages periodically to stdout.

Expected output:

```text
pod/logs-demo created
```

---

## 2. Check the Pod

```bash
kubectl get pod logs-demo
```

Expected output:

```text
NAME        READY   STATUS    RESTARTS   AGE
logs-demo   1/1     Running   0          10s
```

---

## 3. Check Logs

```bash
kubectl logs logs-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl logs logs-demo`: Connects to the kubelet on the node hosting `logs-demo` and retrieves the captured JSON/CRI log files written to `/var/log/pods/...`.

Expected output:

```text
Application started
Connecting to database...
Database connection successful
Application is running
Application is healthy
```

*(You may see the last line multiple times.)*

---

## 4. Follow Logs

Run:

```bash
kubectl logs -f logs-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl logs -f logs-demo`: Flag `-f` (`--follow`) streams log lines continuously to your terminal stdout, similar to Linux `tail -f`.
* Press `Ctrl + C` to stop following.

---

## 5. Why Are Logs Important?

Imagine:

```text
Pod
 │
 └── STATUS = CrashLoopBackOff
```

`kubectl get` tells us: **Something is wrong.**

Then:

```bash
kubectl logs <pod-name>
```

may tell us:

```text
Error connecting to database
```

Now we have a possible reason.

---

## 6. Previous Container Logs

If a container has crashed and restarted, try:

```bash
kubectl logs <pod-name> --previous
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl logs <pod-name> --previous`: Flag `--previous` (`-p`) dumps stdout/stderr from the *dead container instance that just crashed* instead of the newly restarted container instance. Crucial for debugging ephemeral application crashes.

This is very useful for `CrashLoopBackOff` problems.

---

## 7. Multiple Containers

If a Pod has multiple containers:

```bash
kubectl logs <pod-name> -c <container-name>
```

#### 💡 Command Breakdown (cmd-explained):
* `-c <container-name>`: Scopes logs to a single container. If a pod contains both an `app` container and an `istio-proxy` or `logging-agent` sidecar, omitting `-c` causes kubectl to error with `choose one of: [app sidecar]`.

Example:

```bash
kubectl logs my-pod -c backend
```

---

## Useful Commands

```bash
kubectl logs logs-demo
kubectl logs -f logs-demo
kubectl logs logs-demo --previous
kubectl logs logs-demo -c app
kubectl logs logs-demo --tail=50
kubectl logs logs-demo --since=10m --timestamps
```

#### 💡 Command Breakdown (cmd-explained):
* `--tail=50`: Displays only the last 50 lines of logs, avoiding terminal flooding from high-traffic pods.
* `--since=10m`: Filters logs emitted within the past 10 minutes (supports `s`, `m`, `h`).
* `--timestamps`: Prefixes each output line with RFC3339 UTC timestamp, allowing precise correlation with cluster events.

---

## Key Learning

Remember:

```text
kubectl logs
     │
     ▼
"What is the application saying?"
```

Logs are often the first place to look when an application is crashing or behaving unexpectedly.

---

## Reference

* **Kubernetes Logging Architecture:**  
  https://kubernetes.io/docs/concepts/cluster-administration/logging/

---

### 📚 Tech Jargons Demystified:
* **Container Logging (stdout / stderr):** Best practice dictates applications inside Docker/Kubernetes write logs to standard output rather than local disk files. The container engine handles serialization to host disk files (`/var/log/pods`).
* **Log Rotation:** Kubelet periodically rotates log files when they reach maximum size (e.g. 10MB) to prevent worker node disk exhaustion (`DiskPressure`).
* **Log Aggregation:** Production clusters use daemonsets (Fluentd, Promtail, Vector) to ship container logs to centralized indexed search engines (Elasticsearch, Grafana Loki, AWS CloudWatch).

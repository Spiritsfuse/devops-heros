# 01 - Monitoring vs Observability

```text
Monitoring
Observability
```

They are related, but not exactly the same.

---

# Monitoring

Monitoring asks:

> "Is the system healthy?"

Example dashboard:

```text
CPU:        82%
Memory:     70%
Requests:   500/sec
Errors:     20/sec
Latency:    900ms
```

We can create an alert:

```text
IF error_rate > 5%
THEN alert
```

Monitoring is excellent for known problems.

---

# Observability

Observability asks:

> "Why is the system behaving this way?"

Imagine:

```text
Users say:
"The website is slow."
```

Monitoring tells us:

```text
Latency = 2 seconds
```

Observability helps us investigate:

```text
Request
   |
   +-- API = 500ms
   |
   +-- User Service = 200ms
   |
   +-- Payment Service = 100ms
   |
   +-- Database = 1.2s
```

Now we have a clue:

```text
Database = slow
```

---

# Analogy

Imagine a car.

## Monitoring

Dashboard says:

```text
Engine temperature = HIGH
```

We know something is wrong.

## Observability

We inspect:

```text
Coolant level
Engine logs
Temperature history
Sensor readings
```

Now we can investigate why.

---

# Three Main Signals

Observability commonly uses:

```text
Metrics
Logs
Traces
```

Think:

```text
Metrics = Numbers
Logs    = Events
Traces  = Journey
```

---

# Monitoring vs Observability

| Monitoring | Observability |
|---|---|
| Is something wrong? | Why is it wrong? |
| Known failure signals | Explore unknown problems |
| Dashboards/alerts | Metrics + logs + traces |
| Health view | Deep investigation |

They are not competitors btw.

A production system normally uses both.

---

# Example

Suppose:

```text
Website feels slow
```

Monitoring:

```text
Latency > 1 second
```

Observability:

```text
Trace shows:
API -> Order Service -> Database

Database query = 850ms
```

Now the team has a much better starting point.

---

# Key Point

```text
Monitoring:
"Tell me when something is wrong."

Observability:
"Give me enough information to understand what happened."
```

---

# Practical DevOps Application: From Theory to Shell Commands

How do we actually perform Monitoring vs Observability from the terminal?

### 1. Monitoring Commands (Detecting "Is Something Wrong?")
In Kubernetes and Linux environments, monitoring starts with resource consumption checks against predefined thresholds:

```bash
kubectl top nodes
kubectl top pods -A
```

#### 💡 Command Breakdown (`cmd-explained`):
- `kubectl`: The Kubernetes command-line tool that sends REST API requests to the Kubernetes `kube-apiserver`.
- `top`: Queries the cluster's **Metrics Server** to display real-time CPU and Memory utilization snapshots.
- `nodes`: Targets the physical or virtual worker machines forming the cluster.
- `pods`: Targets individual container pods running your applications.
- `-A` (or `--all-namespaces`): Shorthand flag instructing `kubectl` to query across every namespace (e.g., `kube-system`, `monitoring`, `default`) instead of just the currently active one.
- **Theory Connection**: This is **Monitoring** in action. It gives you raw numbers (e.g., node CPU at 94%). You know a threshold is breached, but you do not know *which code path* or *why* it is spiking.

---

### 2. Observability Commands (Investigating "Why Did It Happen?")
When the monitoring alert fires, engineers switch to observability tools to correlate logs, events, and traces:

```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --tail=100 -f
```

#### 💡 Command Breakdown (`cmd-explained`):
- `describe`: Pulls comprehensive metadata, pod conditions (`PodScheduled`, `ContainersReady`), container restart counts, and the **Kubernetes Event Log** (e.g., `OOMKilled`, `FailedScheduling`, or `CrashLoopBackOff`).
- `logs`: Streams standard output (`stdout`) and standard error (`stderr`) emitted by the application runtime.
- `--tail=100`: Reads and displays only the most recent 100 log lines from the container log buffer, preventing terminal overload.
- `-f` (or `--follow`): Keeps the stream open and continuously prints new log entries as they arrive in real time (identical to `tail -f` in Linux).
- **Theory Connection**: This is **Observability**. By correlating the high memory metric with pod crash events and stack trace logs, you diagnose that a memory leak occurred during a specific database query.

---

### 📚 Tech Jargons Demystified:
- **Telemetry**: Automated measurement and data collection from distributed nodes and applications sent to a centralized collection system.
- **Threshold**: A preset numerical boundary (e.g., Latency > 1000ms, Error rate > 5%) that triggers automated alerts.
- **Root Cause Analysis (RCA)**: The systematic debugging methodology used to trace a symptom back to the core bug or failure point.
- **High Cardinality**: Data with many unique values (e.g., User IDs, Transaction IDs, IP addresses). Observability engines thrive on high-cardinality data for surgical filtering.

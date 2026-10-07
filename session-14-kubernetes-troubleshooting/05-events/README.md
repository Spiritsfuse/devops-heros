# Kubernetes Events

Events help us understand what Kubernetes is doing with our resources.

Think of Events as:

> "Kubernetes' activity log for a resource."

---

## 1. Create the Pod

```bash
kubectl apply -f pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f pod.yaml`: Deploys the events demonstration pod, triggering a sequence of control plane events (Scheduling, Image Pulling, Container Creation).

Expected output:

```text
pod/events-demo created
```

---

## 2. Check Events

Run:

```bash
kubectl get events
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get events`: Queries the Event API for recent cluster operational notices across the namespace. Shows Event `TYPE` (`Normal`, `Warning`), `REASON` (`Scheduled`, `Pulled`), the involved `OBJECT`, and detailed diagnostic `MESSAGE`.

You may see:

```text
TYPE     REASON    OBJECT              MESSAGE
Normal   Scheduled Pod/events-demo     Successfully assigned...
Normal   Pulling   Pod/events-demo     Pulling image...
Normal   Pulled    Pod/events-demo     Successfully pulled...
Normal   Created   Pod/events-demo     Created container...
Normal   Started   Pod/events-demo     Started container...
```

*(The exact messages depend on your cluster.)*

---

## 3. Sort Events

Run:

```bash
kubectl get events --sort-by=.lastTimestamp
```

#### 💡 Command Breakdown (cmd-explained):
* `--sort-by=.lastTimestamp`: Orders events chronologically from oldest to newest so the most recent operational failure appears right at the bottom of the output.

This makes recent events easier to understand.

---

## 4. Describe Also Shows Events

Run:

```bash
kubectl describe pod events-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl describe pod events-demo`: Automatically queries and filters the cluster event log specifically for events belonging to `Pod/events-demo`, rendering them chronologically at the bottom under `Events:`.

At the bottom, look for:

```text
Events:
```

---

## 5. Why Are Events Important?

Suppose a Pod is `Pending`. You don't know why.

Run:

```bash
kubectl describe pod <pod-name>
```

You might find:

```text
FailedScheduling
```

with a message explaining that the Pod cannot be scheduled.

Or for an image problem:

```text
Failed
Failed to pull image
```

Events help us find the reason behind the status.

---

## 6. Watch Events

You can watch events:

```bash
kubectl events --watch
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl events --watch`: Modern `kubectl` subcommand (v1.23+) providing a continuously streaming timeline of cluster events.

You can also filter for a specific resource:

```bash
kubectl events --for pod/events-demo
```

Or filter strictly for warning/error events:

```bash
kubectl get events --field-selector type=Warning --sort-by=.lastTimestamp
```

#### 💡 Command Breakdown (cmd-explained):
* `--field-selector type=Warning`: Server-side filtering flag that eliminates routine informational messages (`Normal`), showing only actionable faults like `FailedScheduling`, `Unhealthy`, or `BackOff`.

---

## Useful Commands

```bash
kubectl get events
kubectl get events --sort-by=.lastTimestamp
kubectl events
kubectl events --watch
kubectl describe pod events-demo
kubectl get events --field-selector type=Warning
```

---

## Key Learning

Remember:

```text
kubectl get
     │
     ▼
Current status

kubectl describe
     │
     ▼
Detailed information

Events
     │
     ▼
What Kubernetes tried to do and what happened
```

* Events are the fastest way to understand what the Kubernetes control plane is doing.
* Always filter with `--field-selector type=Warning` to cut through noise during incidents.
* Remember that events expire from `etcd` after 1 hour by default.
* The message in `FailedScheduling` events will tell you exactly why a Pod is stuck in `Pending`.

---

## Reference

* **Kubernetes Events API:**  
  https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/event-v1/

---

### 📚 Tech Jargons Demystified:
* **Event Types (`Normal` vs `Warning`):**
  * `Normal`: Standard informational state changes (pod scheduled, image pulled, container started).
  * `Warning`: Anomalies, errors, or failures (crash backoff, probe failed, insufficient CPU, mount timeout).
* **Event TTL / Retention Period:** Events are stored in `etcd` with a default time-to-live (TTL) of 1 hour (`--event-ttl=1h0m0s` on `kube-apiserver`). For long-term historical audits, organizations ship events to Prometheus or Elasticsearch via tools like `eventrouter`.
* **Field Selector:** A client-side filter evaluated directly on the API server (`--field-selector`) to minimize network bandwidth when querying massive resource lists.

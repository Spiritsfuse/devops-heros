# `kubectl describe`

```bash
kubectl describe
```

If `kubectl get` tells us:
> "Something is wrong."

`kubectl describe` helps us ask:
> "What exactly happened?"

---

## 1. Create the Pod

```bash
kubectl apply -f pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f pod.yaml`: Deploys the demonstration pod defined in `pod.yaml`.

Expected output:

```text
pod/describe-demo created
```

Check:

```bash
kubectl get pod
```

---

## 2. Describe the Pod

Run:

```bash
kubectl describe pod describe-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl describe pod describe-demo`: Fetches detailed live runtime configuration and status from the API server. Unlike `kubectl get`, `describe` merges multiple API objects (Pod, Node, Events, VolumeMounts) into a human-readable diagnostic report.

The output contains many sections. Important sections include:

* **Name**
* **Namespace**
* **Labels**
* **Status**
* **IP**
* **Containers**
* **Conditions**
* **Events**

---

## 3. Containers Section

You can see:

```text
Containers:
  nginx:
    Image: nginx:1.27
    State: Running
    Ready: True
```

This tells us:
* Which image is running
* Container state
* Whether it is ready

---

## 4. Events Section

At the bottom, you may see:

```text
Events:
  Type     Reason    Message
  Normal   Pulling   Pulling image
  Normal   Pulled    Successfully pulled image
  Normal   Created   Created container
  Normal   Started   Started container
```

Events are extremely useful when troubleshooting.

---

## 5. Compare `get` and `describe`

**`kubectl get`**
```bash
kubectl get pod
```
Gives us a quick summary.

**`kubectl describe`**
```bash
kubectl describe pod describe-demo
```
Gives us detailed information.

Think of it like this:

```text
get
 │
 └── quick view

describe
 │
 └── detailed investigation
```

---

## 6. Describe Other Resources

**Deployment:**
```bash
kubectl describe deployment <deployment-name>
```

**Service:**
```bash
kubectl describe service <service-name>
```

**Node:**
```bash
kubectl describe node <node-name>
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl describe deployment`: Reveals deployment rollout strategy, replica set revisions, and scaling conditions (`Progressing`, `Available`).
* `kubectl describe service`: Lists matched pod IP endpoints, session affinity settings, and load balancer provisioning events.
* `kubectl describe node`: Displays allocated vs capacity CPU/memory percentages, node taints, and daemon conditions (`MemoryPressure`, `DiskPressure`, `NetworkUnavailable`).

---

## Troubleshooting Habit

If you see:

```text
STATUS: Pending
```

Don't immediately delete the Pod.

Run:

```bash
kubectl describe pod <pod-name>
```

Then look at the **Events** section.

Kubernetes documentation specifically recommends `kubectl describe pod` as one of the standard ways to investigate Pod problems.

---

## Key Learning

Remember:

```text
kubectl get
     │
     ▼
"What is happening?"

kubectl describe
     │
     ▼
"Why is it happening?"
```

---

## Reference

* **Kubernetes Pod Lifecycle:**  
  https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/

---

### 📚 Tech Jargons Demystified:
* **Pod Conditions:**
  * `PodScheduled`: The pod was assigned to a node.
  * `Initialized`: All init containers have completed successfully.
  * `ContainersReady`: All containers in the pod are ready.
  * `Ready`: The pod is capable of serving requests and should be added to matching Services.
* **Container State Lifecycle:**
  * `Waiting`: Pulling images or waiting for volumes.
  * `Running`: Process is active.
  * `Terminated`: Container finished execution or crashed.
* **Exit Codes:**
  * `0`: Normal completion / successful exit.
  * `1` or `2`: Application threw an unhandled error / missing config.
  * `137`: SIGKILL (`128 + 9`), typically OOMKilled (Out Of Memory) when exceeding container memory limits.
  * `143`: SIGTERM (`128 + 15`), graceful shutdown signal from Kubernetes.

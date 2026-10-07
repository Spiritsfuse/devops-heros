# `kubectl get`

```bash
kubectl get
```

Think of `kubectl get` as:
 
> "Kubernetes, show me what is currently happening."

---

## 1. Create the Pod

Run:

```bash
kubectl apply -f pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f pod.yaml`: Submits the pod manifest to the active namespace, creating the `get-demo` pod object in etcd.

Expected output:

```text
pod/get-demo created
```

---

## 2. Check Pods

Run:

```bash
kubectl get pods
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pods`: Queries API server for a tabulated list of Pods in the active namespace. Shows container readiness (`1/1`), lifecycle status (`Running`), crash restart counts (`0`), and age.

Expected output:

```text
NAME       READY   STATUS    RESTARTS   AGE
get-demo   1/1     Running   0          10s
```

---

## 3. Understand The Output

* **NAME**: Name of the Pod.
* **READY**: Number of ready containers.
* **STATUS**: Current Pod status.
* **RESTARTS**: Number of container restarts.
* **AGE**: How long the Pod has existed.

---

## 4. Get More Information

Run:

```bash
kubectl get pods -o wide
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pods -o wide`: Formats output with expanded diagnostic columns: Pod IP address (`10.244.0.5`), host worker node name (`minikube`), designated nomination nodes, and readiness gate checks.

You will see additional information such as:

* Pod IP
* Node
* Container status

Example output:

```text
NAME       READY   STATUS    RESTARTS   AGE   IP           NODE
get-demo   1/1     Running   0          20s   10.244.0.5   minikube
```

*(The exact IP and node name will be different on your cluster.)*

---

## 5. Check Different Resources

**Pods:**
```bash
kubectl get pods
```

**Services:**
```bash
kubectl get services
```

**Deployments:**
```bash
kubectl get deployments
```

**Nodes:**
```bash
kubectl get nodes
```

**All resources:**
```bash
kubectl get all
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get services`: Lists cluster service virtual IPs, types (ClusterIP, NodePort, LoadBalancer), and external port bindings.
* `kubectl get deployments`: Shows desired, current, up-to-date, and available replica counts.
* `kubectl get nodes`: Lists cluster worker and control plane physical/VM nodes and their health readiness.
* `kubectl get all`: Composite query combining pods, services, daemonsets, deployments, replicasets, and statefulsets in the current namespace.

---

## 6. Watch Changes

Run:

```bash
kubectl get pods -w
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pods -w`: The `-w` (`--watch`) flag opens a persistent streaming connection to the API server event channel, printing line-by-line updates in real time whenever any pod changes phase or container state.

Now delete the Pod from another terminal:

```bash
kubectl delete pod get-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl delete pod get-demo`: Sends a SIGTERM termination signal to the container, waits for grace period (default 30s), then purges the object from etcd.

You can watch the Pod disappear in real time.

---

## 7. Troubleshooting Habit

When something is not working, start with:

```bash
kubectl get pods
```

Then look at:
* `STATUS`
* `READY`
* `RESTARTS`

For example:

```text
NAME       READY   STATUS             RESTARTS
my-app     0/1     CrashLoopBackOff   5
```

This immediately tells us: **Something is wrong with the container.**

But `kubectl get` only tells us **what** is happening. Next we need:

```bash
kubectl describe
kubectl logs
```

to understand **why**.

---

## Useful Commands

```bash
kubectl get pods
kubectl get pods -o wide
kubectl get all
kubectl get nodes
kubectl get services
kubectl get deployments
kubectl get pods -w
```

---

## Key Learning

Remember:

```text
kubectl get
     │
     ▼
"What is happening?"
```

It gives us the current state of Kubernetes resources.

---

## Reference

* **Kubernetes Command Line Tool (kubectl):**  
  https://kubernetes.io/docs/reference/kubectl/

---

### 📚 Tech Jargons Demystified:
* **Output Formatting Flags (`-o`):**
  * `-o wide`: Additional columns (IP, Node, OS image).
  * `-o yaml` / `-o json`: Prints full, live Kubernetes API specification including runtime status and annotations.
  * `-o jsonpath='{...}'`: Filters specific nested JSON values using expression syntax.
* **READY Fraction (`0/1` vs `1/1`):** Indicates $\text{Ready Containers} / \text{Total Containers}$. A pod with `0/1` and status `Running` is running its process, but failing its `readinessProbe`.
* **Streaming Watch (`-w`):** Instead of polling the API server in a loop, `-w` leverages HTTP chunked transfer / server-sent events to react instantaneously to state transitions.

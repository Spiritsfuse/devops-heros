#  `Pending` Pods

The goal is to understand:

```text
Pod is Pending
     │
     ▼
   Why?
     │
     ▼
Find the reason
     │
     ▼
  Fix it
```

---

## 1. Create The Broken Pod

```bash
kubectl apply -f broken-pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f broken-pod.yaml`: Deploys a pod requesting a node with label `kubernetes.io/hostname: node-that-does-not-exist`.

Check:

```bash
kubectl get pod pending-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pod pending-demo`: Shows the pod stuck in `Pending` phase. Notice `NODE` shows `<none>` because `kube-scheduler` could not bind the pod to any existing node.

Expected output:

```text
NAME           READY   STATUS    RESTARTS   AGE
pending-demo   0/1     Pending   0          10s
```

*(The Pod remains Pending.)*

---

## 2. Why Is It Pending?

Run:

```bash
kubectl describe pod pending-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl describe pod pending-demo`: Displays the scheduling failure reason under `Events:`. Look for `Warning FailedScheduling 0/1 nodes are available: 1 node(s) didn't match Pod's node selector`.

Look at the **Events** section. You should see a scheduling-related message.

The Pod contains:

```yaml
nodeSelector:
  kubernetes.io/hostname: node-that-does-not-exist
```

Kubernetes cannot find a node matching this selector.

Therefore:

```text
Scheduler
    │
    ▼
Looks for matching node
    │
    ▼
No matching node
    │
    ▼
Pod remains Pending
```

---

## 3. Check Nodes

Run:

```bash
kubectl get nodes
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get nodes`: Verifies what nodes physically exist and are reported `Ready`.
* Run `kubectl get nodes --show-labels` to inspect active key-value labels assigned to each node.

Example output:

```text
NAME       STATUS   ROLES
minikube   Ready    control-plane
```

Our Pod asks for `node-that-does-not-exist`, but that node does not exist.

---

## 4. Fix The Pod

Delete:

```bash
kubectl delete pod pending-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl delete pod pending-demo`: Purges the unschedulable pod from the scheduling queue.

Apply:

```bash
kubectl apply -f fixed-pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f fixed-pod.yaml`: Reapplies with the faulty `nodeSelector` removed. The scheduler immediately places the pod on `minikube`.

Check:

```bash
kubectl get pod pending-demo
```

Expected output:

```text
NAME           READY   STATUS
pending-demo   1/1     Running
```

---

## 5. Other Reasons For Pending Pods

A Pod can remain Pending because of:
* Insufficient CPU
* Insufficient memory
* Node selector mismatch
* Affinity rules
* Taints and tolerations
* PVC not available
* Scheduling constraints

Do not assume every Pending Pod has the same problem.

---

## Troubleshooting Flow

```text
kubectl get pods
       │
       ▼
    Pending
       │
       ▼
kubectl describe pod
       │
       ▼
  Check Events
       │
       ▼
  Check nodes
       │
       ▼
 Check resources
       │
       ▼
Check selectors / affinity
       │
       ▼
Check PVC if used
       │
       ▼
      Fix
```

---

## Key Learning

Remember:

```text
Pending = Pod has not successfully been scheduled/started yet.
```

The first place to look is usually:

```bash
kubectl describe pod <pod-name>
```

and especially the **Events** section.

* A Pod in `Pending` with `NODE: <none>` is waiting on `kube-scheduler`.
* Look at `PodScheduled: False` in Conditions.
* Always check the message under `Warning FailedScheduling` in Events.
* The most frequent causes are CPU/RAM request over-allocation and invalid node selectors.

---

## Reference

* **Kubernetes Scheduling:**  
  https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/

---

### 📚 Tech Jargons Demystified:
* **Kube-Scheduler Filtering & Scoring:**
  * **Filtering (Predicates):** Filters out nodes that do not satisfy pod requirements (insufficient RAM/CPU, taints, volume zone mismatches).
  * **Scoring (Priorities):** Ranks surviving candidate nodes to pick the best fit. If 0 nodes survive filtering, the pod is stuck in `Pending`.
* **NodeSelector vs Node Affinity:**
  * `nodeSelector`: Hard, basic key-value equality match (`kubernetes.io/os: linux`).
  * `nodeAffinity`: Advanced expressive rules supporting operators (`In`, `NotIn`, `Exists`) and soft/preferred scheduling (`preferredDuringSchedulingIgnoredDuringExecution`).
* **Taints and Tolerations:**
  * **Taint:** Applied to a Node to repel certain pods (e.g. `node-role.kubernetes.io/control-plane:NoSchedule`).
  * **Toleration:** Applied to a Pod allowing it to schedule onto matching tainted nodes.
* **VolumeBindingMode WaitForFirstConsumer:** A PVC in this mode causes pods to remain in `Pending` until the scheduler places the pod and prompts storage creation in that node's zone.

---

## 5. Other Reasons For Pending Pods

A Pod can remain Pending because of:
* Insufficient CPU
* Insufficient memory
* Node selector mismatch
* Affinity rules
* Taints and tolerations
* PVC not available
* Scheduling constraints

Do not assume every Pending Pod has the same problem.

---

## Troubleshooting Flow

```text
kubectl get pods
       │
       ▼
    Pending
       │
       ▼
kubectl describe pod
       │
       ▼
  Check Events
       │
       ▼
  Check nodes
       │
       ▼
 Check resources
       │
       ▼
Check selectors / affinity
       │
       ▼
Check PVC if used
       │
       ▼
      Fix
```

---

## Key Learning

Remember:

```text
Pending = Pod has not successfully been scheduled/started yet.
```

The first place to look is usually:

```bash
kubectl describe pod <pod-name>
```

and especially the **Events** section.

* A Pod in `Pending` with `NODE: <none>` is waiting on `kube-scheduler`.
* Look at `PodScheduled: False` in Conditions.
* Always check the message under `Warning FailedScheduling` in Events.
* The most frequent causes are CPU/RAM request over-allocation and invalid node selectors.

---

## Reference

* **Kubernetes Scheduling:**  
  https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/

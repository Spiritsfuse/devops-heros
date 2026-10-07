# Kubernetes Persistent Storage


## What will we work with?

* PersistentVolume (`PV`)
* PersistentVolumeClaim (`PVC`)
* Pod
* Persistent storage

---

## 1. The Problem

Suppose our application stores:

* `student-data.txt`
* `database-data`
* `images`
* `logs`

inside a Pod.

If the Pod is deleted, we don't want our important data to disappear.

For this, Kubernetes provides persistent storage.

---

## 2. PersistentVolume

A PersistentVolume is a storage resource available to the Kubernetes cluster.

Think of it like:

> **PV = Storage available in the cluster**

Our example creates:

* Capacity: `1Gi`
* Access Mode: `ReadWriteOnce`

Check the PV:

```bash
kubectl get pv
```

---

## 3. PersistentVolumeClaim

A PersistentVolumeClaim is a request for storage.

Think of it like:

```text
PV
 │
 │ provides storage
 ▼
PVC
 │
 │ requests storage
 ▼
Pod
```

Our PVC requests:

* Capacity: `500Mi`
* Access Mode: `ReadWriteOnce`

---

## 4. Create the PV

Run:

```bash
kubectl apply -f pv.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f pv.yaml`: Submits the PersistentVolume definition to the cluster API server. Since PV is a cluster-scoped resource (not bound to any namespace), it becomes globally available for matching claims.

Check:

```bash
kubectl get pv
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pv`: Lists all physical/virtual storage volumes configured in the cluster. Note the `STATUS` initially displays `Available` (ready to be bound).

Expected output:

```text
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS
student-pv   1Gi        RWO            Retain           Available
```

---

## 5. Create the PVC

Run:

```bash
kubectl apply -f pvc.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f pvc.yaml`: Submits the PersistentVolumeClaim manifest in the active namespace. Kubernetes' PV controller immediately searches for an unassigned PV matching the requested capacity and access mode.

Check:

```bash
kubectl get pvc
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pvc`: Checks the claim. When successfully paired, the `STATUS` transitions to `Bound` and the `VOLUME` column lists `student-pv`.

Expected output:

```text
NAME          STATUS   VOLUME
student-pvc   Bound    student-pv
```

**Bound** means the PVC has been connected to a suitable PV.

---

## 6. Create the Pod

Run:

```bash
kubectl apply -f pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f pod.yaml`: Deploys the consumer Pod. The pod's spec mounts the volume backed by `student-pvc` onto `/data`.

Check:

```bash
kubectl get pods
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pods`: Monitors pod startup. Kubelet attaches and formats the storage before launching container processes.

Expected output:

```text
NAME            READY   STATUS
storage-demo    1/1     Running
```

---

## 7. Test Persistent Storage

Enter the Pod:

```bash
kubectl exec -it storage-demo -- bash
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl exec -it storage-demo -- bash`: Opens an interactive Bash shell session directly inside the running container.

Create a file inside the mount path:

```bash
echo "Kubernetes Storage" > /data/message.txt
```

#### 💡 Command Breakdown (cmd-explained):
* `echo "..." > /data/message.txt`: Writes text to a file located inside `/data`. Because `/data` is backed by the persistent volume, the bits are physically written to the underlying storage volume rather than the container's temporary read-write layer.

Read it:

```bash
cat /data/message.txt
```

Output:

```text
Kubernetes Storage
```

Exit:

```bash
exit
```

---

## 8. Delete the Pod

Delete the running Pod:

```bash
kubectl delete pod storage-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl delete pod storage-demo`: Completely deletes and unmounts the Pod. Any data written inside the non-mounted root filesystem of the container is permanently erased.

Create it again:

```bash
kubectl apply -f pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f pod.yaml`: Launches a brand new container instance. Kubelet attaches the existing PVC (`student-pvc`) back onto the new container's `/data` directory.

Now check the file:

```bash
kubectl exec storage-demo -- cat /data/message.txt
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl exec storage-demo -- cat /data/message.txt`: Non-interactive execution of `cat` inside the new container. The original data is returned intact!

Expected output:

```text
Kubernetes Storage
```

The Pod was deleted, but the data is still available.

---

## 9. Why Did The Data Stay?

Because the Pod was using:

```text
Pod
 │
 ▼
PVC
 │
 ▼
PV
 │
 ▼
Storage
```

The storage has a lifecycle independent of the individual Pod.

---

## 10. Access Modes

| Access Mode | Code | Description |
| :--- | :--- | :--- |
| **ReadWriteOnce** | `RWO` | Volume can be mounted read/write by **one node**. |
| **ReadOnlyMany** | `ROX` | Volume can be mounted read-only by **many nodes**. |
| **ReadWriteMany** | `RWX` | Volume can be mounted read/write by **many nodes**. |
| **ReadWriteOncePod** | `RWOP` | Volume can be mounted read/write by **a single Pod**. |

---

## Useful Commands

```bash
kubectl get pv
kubectl get pvc
kubectl describe pv student-pv
kubectl describe pvc student-pvc
kubectl get pods
kubectl describe pod storage-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl describe pv student-pv`: Displays low-level storage driver parameters (e.g. host directory path, CSI volume handle, reclaim policy, binding timestamp).
* `kubectl describe pvc student-pvc`: Checks PVC status conditions, volume capacity allocations, and storage class associations.
* `kubectl describe pod storage-demo`: Shows pod storage volume mounts, identifying whether storage attach/mount operations succeeded or encountered `FailedMount` events.

---

## Key Learning

Remember:

* **PV** = storage
* **PVC** = request for storage
* **Pod** = uses the PVC

---

## Reference

* **Persistent Volumes:**  
  https://kubernetes.io/docs/concepts/storage/persistent-volumes/

---

### 📚 Tech Jargons Demystified:
* **PV Lifecycle Statuses:**
  * `Available`: Free volume ready to be claimed.
  * `Bound`: Claimed and paired with a PVC.
  * `Released`: PVC was deleted, but storage resource is not yet recycled by the cluster.
  * `Failed`: Automated reclamation failed.
* **Persistent Storage Decoupling:** Architectural design separating administrative storage allocation (PV) from developer consumption requests (PVC), enabling cloud-agnostic application deployments.
* **Storage Mounting vs Container Layer:** Files written to container root filesystems are lost on container restart; files written to volume mount points bypass container storage drivers (`overlay2`) and persist on the persistent storage volume.

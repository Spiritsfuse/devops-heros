# Kubernetes Volumes, Persistent Storage & StorageClasses

## Student Information
- **Name:** Dhruv Sharma
- **Enrollment Number:** 24BCS10294
- **Session:** Session 13 – Storage, HPA & Probes

---

## 1. Introduction: Why Do We Need Kubernetes Storage?
Containers in Kubernetes are ephemeral by design. If a container crashes, `kubelet` restarts it with a clean filesystem state; any files written by the prior process are lost. Furthermore, when multiple containers share a Pod, they often require a shared workspace.

Kubernetes abstracts storage through several volume plugins and primitives, decoupling storage lifecycle from individual container lifecycles.

---

## 2. Ephemeral & Node-Tied Storage

### 2.1 `emptyDir`
An `emptyDir` volume is created as soon as a Pod is assigned to a Node, and exists as long as that Pod runs on that node.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo
spec:
  containers:
  - name: writer
    image: alpine
    command: ["sh", "-c", "echo 'Hello from emptyDir' > /cache/data.txt && sleep 3600"]
    volumeMounts:
    - name: cache-volume
      mountPath: /cache
  - name: reader
    image: alpine
    command: ["sh", "-c", "sleep 5 && cat /cache/data.txt && sleep 3600"]
    volumeMounts:
    - name: cache-volume
      mountPath: /cache
  volumes:
  - name: cache-volume
    emptyDir: {}
```

- **Lifecycle**: Tied strictly to the Pod. If the Pod is terminated or rescheduled to another node, all data inside `emptyDir` is erased.
- **Use Cases**: Scratch space, temporary cache, sharing files between sidecar and main application containers.

### 2.2 `hostPath`
A `hostPath` volume mounts an existing directory or file directly from the host node's filesystem into the Pod.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo
spec:
  containers:
  - name: app
    image: nginx:alpine
    volumeMounts:
    - name: node-storage
      mountPath: /var/log/app
  volumes:
  - name: node-storage
    hostPath:
      path: /var/log/node-app-logs
      type: DirectoryOrCreate
```

- **Lifecycle**: Persists on the specific worker node's disk even if the Pod restarts. However, if the Pod is rescheduled onto a different node, it cannot access the first node's data.
- **Security & Production Warning**: Bypasses container isolation. Recommended only for cluster agents (e.g., node monitoring daemons, log shippers like Fluentd/Promtail) requiring access to `/var/log` or `/var/lib/docker`.

---

## 3. Persistent Volumes (PV) & Persistent Volume Claims (PVC)

To enable persistent, portable storage across pod migrations, Kubernetes separates storage provisioning into two decoupled API objects:

```text
  Storage Administrator                   Application Developer
          │                                         │
          ▼                                         ▼
   PersistentVolume (PV) ◄─── Bound ───► PersistentVolumeClaim (PVC)
   [ 10Gi, ReadWriteOnce,                       [ Requests 5Gi,
     Retain Policy, Host/NFS ]                    ReadWriteOnce ]
                                                    │
                                                    ▼
                                            Pod mounts PVC
```

### 3.1 PersistentVolume (PV)
A piece of cluster-wide storage provisioned by an administrator or dynamically provisioned using StorageClasses:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data
```

### 3.2 PersistentVolumeClaim (PVC)
A request for storage by a developer/user (specifies size, access modes):
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

### 3.3 Access Modes
- **ReadWriteOnce (RWO)**: Volume can be mounted as read-write by a single node.
- **ReadOnlyMany (ROX)**: Volume can be mounted read-only by multiple nodes simultaneously.
- **ReadWriteMany (RWX)**: Volume can be mounted read-write by many nodes (requires NFS, Ceph, EFS, etc.).
- **ReadWriteOncePod (RWOP)**: Volume can be mounted as read-write by a single Pod.

---

## 4. StorageClass & Dynamic Provisioning

### Why StorageClasses?
In static provisioning, cluster administrators must pre-create PVs manually. If developers request PVCs of sizes that don't match, or if storage runs out, deployments fail.

A **StorageClass** enables **Dynamic Provisioning**:
1. Developer creates a PVC referencing a `storageClassName`.
2. The storage provisioner (e.g., AWS EBS CSI, GCP PD CSI, Minikube hostpath-provisioner) automatically provisions the underlying cloud disk/volume.
3. A matching PV is created and bound to the PVC on-demand.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ebs
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  type: gp3
```

### PVC Requesting Dynamic Provisioning:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  storageClassName: fast-ebs
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

---

## 5. Summary Comparison Matrix

| Storage Type | Managed By | Lifetime | Multi-Node Access | Dynamic Provisioning |
| :--- | :--- | :--- | :---: | :---: |
| **`emptyDir`** | Pod Controller | Tied to Pod lifespan | No (single Pod) | Built-in |
| **`hostPath`** | Node Filesystem | Node lifetime | No (tied to 1 node) | Manual |
| **Static `PV / PVC`** | Cluster Admin | Independent of Pod | Depends on CSI driver | Manual |
| **Dynamic `StorageClass`** | Storage Provisioner | Independent of Pod | Depends on CSI driver | Fully Automated |

---

## 6. Hands-On Verification & Inspection Commands

```bash
# 1. List all PersistentVolumes and PersistentVolumeClaims
kubectl get pv,pvc

# 2. Check PVC binding status and volume details
kubectl describe pvc app-pvc

# 3. View available cluster StorageClasses
kubectl get storageclass

# 4. Verify data sharing across containers inside an emptyDir Pod
kubectl exec -it emptydir-demo -c reader -- cat /cache/data.txt
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pv,pvc`: Compares physical/cloud storage assets (`PV`) against developer claims (`PVC`). Checks the `STATUS` column to verify that claims show `Bound` rather than `Pending` or `Lost`.
* `kubectl describe pvc app-pvc`: Inspects the claim lifecycle, showing requested capacity, access modes, matching PV volume name, and controller events (e.g. provisioner timeouts or insufficient volume size).
* `kubectl get storageclass` (alias `kubectl get sc`): Lists registered dynamic CSI storage provisioners, default storage classes (marked with `(default)`), and volume binding modes.
* `kubectl exec -it emptydir-demo -c reader -- cat /cache/data.txt`:
  * `-c reader`: Directs the exec call to the `reader` container in a multi-container pod.
  * `cat /cache/data.txt`: Reads the file written by the sibling `writer` container, proving that `emptyDir` enables local shared RAM/disk communication across containers in the same Pod.

---

### 📚 Tech Jargons Demystified:
* **CSI (Container Storage Interface):** An industry-standard specification allowing third-party storage vendors (AWS EBS, GCP Persistent Disk, Azure Disk, Ceph, Portworx) to write plugins for Kubernetes without modifying core Kubernetes source code.
* **PersistentVolumeReclaimPolicy:**
  * `Retain`: When a PVC is deleted, the underlying PV and disk data remain intact for manual administrator recovery.
  * `Delete`: When a PVC is deleted, the backend cloud storage asset (e.g., AWS EBS volume) is automatically destroyed.
* **volumeBindingMode:**
  * `Immediate`: Storage is provisioned immediately upon PVC creation before knowing which node the pod will run on.
  * `WaitForFirstConsumer`: Postpones storage provisioning and binding until a Pod consuming the PVC is actually scheduled, guaranteeing the storage volume is created in the exact same Availability Zone (AZ) as the worker node.

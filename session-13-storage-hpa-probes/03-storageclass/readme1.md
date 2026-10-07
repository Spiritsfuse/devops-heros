# Kubernetes StorageClass

---

## 1. The Problem With Manual PV Creation

Suppose 100 developers need storage.

Without dynamic provisioning:

```text
Developer
    │
    ▼
Creates PVC
    │
    ▼
Admin manually creates PV
```

This can become difficult to manage.

Kubernetes provides **StorageClass** to solve this problem.

---

## 2. What Is StorageClass?

A StorageClass describes a type of storage that can be dynamically provisioned.

### Simple idea:

```text
PVC
 │
 ▼
StorageClass
 │
 ▼
Provisioner
 │
 ▼
PV
```

The PV can be created automatically when the PVC needs it.

---

## 3. Check Existing StorageClasses

Run:

```bash
kubectl get storageclass
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get storageclass`: Queries the API server for registered dynamic volume provisioners. The output indicates the storage provider (`k8s.io/minikube-hostpath`, `ebs.csi.aws.com`), reclaim policy, and whether a class is marked as default with `(default)`.

On Minikube, you may see something similar to:

```text
NAME                 PROVISIONER
standard (default)   k8s.io/minikube-hostpath
```

The exact output can be different depending on your Kubernetes environment.

---

## 4. Check StorageClass Details

Run:

```bash
kubectl describe storageclass standard
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl describe storageclass standard`: Examines configuration parameters including provisioner driver, mount options, expansion capability, and volume binding mode.

This helps us understand:

* Provisioner
* Reclaim policy
* Volume binding mode
* Whether it is the default StorageClass

---

## 5. Create Dynamic PVC

Our `pvc.yaml` contains:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 500Mi
```

Apply it:

```bash
kubectl apply -f pvc.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f pvc.yaml`: Creates the PVC referencing `storageClassName: standard`. Triggers the background CSI provisioner to allocate a dedicated storage volume and auto-generate a matching PV without human intervention.

---

## 6. Check PVC

Run:

```bash
kubectl get pvc
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pvc`: Checks claim status. Notice that the volume name is dynamically assigned (e.g. `pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).

You should see something similar to:

```text
NAME          STATUS   VOLUME
dynamic-pvc   Bound    pvc-xxxxxxxx
```

**Bound** means the PVC received storage.

---

## 7. Check PV

Now run:

```bash
kubectl get pv
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pv`: Lists the newly generated PersistentVolume created on-the-fly by the provisioner. Its capacity matches the claim's request (`500Mi` or rounded minimum allocation).

You should see a PV that was dynamically created.

The exact PV name will be different on your cluster.

---

## 8. What Happened?

We did not manually create a PV.

We created:

```text
PVC
 │
 ▼
StorageClass
 │
 ▼
Dynamic provisioning
 │
 ▼
PV
```

This is called **dynamic provisioning**.

---

## 9. Default StorageClass

A cluster can have a default StorageClass.

Check it:

```bash
kubectl get storageclass
```

You may see:

```text
standard (default)
```

When a PVC does not specify a `storageClassName`, Kubernetes can use the default StorageClass, depending on the cluster configuration.

---

## Useful Commands

```bash
kubectl get storageclass
kubectl describe storageclass standard
kubectl get pvc
kubectl get pv
kubectl describe pvc dynamic-pvc
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl describe pvc dynamic-pvc`: Shows dynamic provisioning events (e.g. `ProvisioningSucceeded: Successfully provisioned volume pvc-xxxx`).

---

## Key Learning

Remember:

* **PV**: Storage available
* **PVC**: Storage request
* **StorageClass**: Helps create storage dynamically

---

## Reference

* **Storage Classes:**  
  https://kubernetes.io/docs/concepts/storage/storage-classes/

---

### 📚 Tech Jargons Demystified:
* **Dynamic Provisioning:** The automated process where the cluster automatically creates physical or cloud storage assets when a developer submits a PVC, eliminating administrative ticket delays.
* **StorageClass Provisioner:** The volume plugin (e.g., `ebs.csi.aws.com` for AWS EBS or `pd.csi.storage.gke.io` for GCP) responsible for calling cloud APIs to create, resize, and delete disks.
* **allowVolumeExpansion:** A flag on StorageClasses (`allowVolumeExpansion: true`) enabling developers to increase PVC storage capacity online without recreating the volume or experiencing downtime.
* **Default StorageClass Annotation:** A metadata annotation (`storageclass.kubernetes.io/is-default-class: "true"`) marking which class provisions storage when a PVC omits the `storageClassName` field.

# Rollback

```bash
helm rollback my-app 1
```

If an upgrade breaks your application, rollback returns you to a previous working revision in seconds.

---

## 1. Why Rollback Matters

```text
Revision 1: Working (1 replica, nginx:1.24)
Revision 2: Broken  (bad image tag: nginx:doesnotexist)
```

Without Helm rollback, you must manually fix YAML and re-apply.  
With Helm rollback, you type one command.

---

## 2. Setup: Install the Chart

Use the `app-chart` from topic 07.

```bash
helm install rollback-demo ./app-chart
```

Expected output:

```text
NAME: rollback-demo
STATUS: deployed
REVISION: 1
```

---

## 3. Upgrade to a Broken Version

```bash
helm upgrade rollback-demo ./app-chart --set image.tag=doesnotexist
```

Check the pods:

```bash
kubectl get pods
```

Expected output:

```text
NAME                         READY   STATUS             RESTARTS
rollback-demo-app-xxxx       0/1     ImagePullBackOff   0
```

The pod fails because the image tag does not exist.

---

## 4. Check Release History

```bash
helm history rollback-demo
```

#### 💡 Command Breakdown (cmd-explained):
- `helm history`: Displays the entire revision history of a release, showing revision numbers, timestamps, status (`superseded`, `deployed`), chart version, and description of actions taken.

Expected output:

```text
REVISION   STATUS      DESCRIPTION
1          superseded  Install complete
2          deployed    Upgrade complete
```

*(Revision 2 is the broken one even though the pod is failing.)*

---

## 5. Rollback to Revision 1

```bash
helm rollback rollback-demo 1
```

#### 💡 Command Breakdown (cmd-explained):
- `helm rollback`: Reverts a release to a specific previous revision number.
- `rollback-demo`: The release name.
- `1`: The target revision number to restore. (If omitted, defaults to the previous revision `N-1`).

Expected output:

```text
Rollback was a success! Happy Helming!
```

---

## 6. Check Pods After Rollback

```bash
kubectl get pods
```

Expected output:

```text
NAME                         READY   STATUS    RESTARTS
rollback-demo-app-yyyy       1/1     Running   0
```

The pod is healthy again. Helm re-deployed revision 1's configuration.

---

## 7. History After Rollback

```bash
helm history rollback-demo
```

Expected output:

```text
REVISION   STATUS      DESCRIPTION
1          superseded  Install complete
2          superseded  Upgrade complete
3          deployed    Rollback to 1
```

Rollback creates a new revision (3). It does not delete the history.

---

## 8. Use --atomic for Auto Rollback

During upgrade, use `--atomic` to auto-rollback on failure:

```bash
helm upgrade rollback-demo ./app-chart \
  --set image.tag=doesnotexist \
  --atomic \
  --timeout 60s
```

#### 💡 Command Breakdown (cmd-explained):
- `helm upgrade rollback-demo ./app-chart`: Initiates release upgrade.
- `--set image.tag=doesnotexist`: Supplies bad image configuration to simulate a failure.
- `--atomic`: If set, the upgrade process rolls back changes automatically if the release fails to deploy or become ready.
- `--timeout 60s`: Maximum duration Helm waits for pods, services, and workloads to enter a `Ready` state before marking the deployment as failed and triggering the atomic rollback.

If pods do not become ready within 60 seconds, Helm automatically rolls back.

---

## Clean Up

```bash
helm uninstall rollback-demo
```

#### 💡 Command Breakdown (cmd-explained):
- `helm uninstall rollback-demo`: Removes the release and deletes its Kubernetes pods, deployments, and metadata.

---

## Key Learning

```text
helm history <release>     = list all revisions
helm rollback <release> N  = go back to revision N
--atomic                   = auto rollback if upgrade fails
```

---

### 📚 Tech Jargons Demystified:
- **Superseded:** A revision status in Helm indicating that this configuration was previously active but has been replaced by a newer upgrade or rollback revision.
- **Atomic Upgrade (`--atomic`):** An all-or-nothing deployment guarantee. If any pod fails readiness checks within the `--timeout` window, Helm automatically executes a rollback to the previous stable revision.
- **Rollback Revision Increment:** Helm rollbacks do not rewrite history or delete revisions; they create a new revision (e.g., Revision 3 with description "Rollback to 1") for full traceability and auditing.

---

## Reference

* **Helm rollback:** https://helm.sh/docs/helm/helm_rollback/


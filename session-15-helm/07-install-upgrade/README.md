# Install and Upgrade

```bash
helm install my-app ./my-chart
helm upgrade my-app ./my-chart
```

These two commands manage the full lifecycle of a release.

---

## 1. Create the Chart

```bash
mkdir -p app-chart/templates
```

`app-chart/Chart.yaml`:

```yaml
apiVersion: v2
name: app-chart
description: Install and upgrade demo
type: application
version: 0.1.0
appVersion: "1.0"
```

`app-chart/values.yaml`:

```yaml
replicaCount: 1
image:
  repository: nginx
  tag: "1.24"
```

`app-chart/templates/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-app
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

---

## 2. Install the Chart

```bash
helm install web-app ./app-chart
```

#### 💡 Command Breakdown (cmd-explained):
- `helm install`: Packages and deploys a Helm chart to the active Kubernetes cluster as a new release.
- `web-app`: The chosen release name for this deployment instance.
- `./app-chart`: Path to the chart directory containing `Chart.yaml`, `values.yaml`, and `templates/`.

Expected output:

```text
NAME: web-app
LAST DEPLOYED: ...
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

Check the deployment:

```bash
kubectl get pods
```

#### 💡 Command Breakdown (cmd-explained):
- `kubectl get pods`: Queries the Kubernetes API server for all pods in the current namespace (`default`), displaying their readiness and status.

Expected output:

```text
NAME                        READY   STATUS    RESTARTS   AGE
web-app-app-xxxx            1/1     Running   0          10s
```

---

## 3. Check Release History

```bash
helm list
```

#### 💡 Command Breakdown (cmd-explained):
- `helm list` (or `helm ls`): Lists all deployed releases in the current Kubernetes namespace along with their status, chart version, and current revision number. Use `-A` or `--all-namespaces` to see releases across all namespaces.

Expected output:

```text
NAME      NAMESPACE   REVISION   STATUS     CHART
web-app   default     1          deployed   app-chart-0.1.0
```

---

## 4. Upgrade with a New Value

Upgrade the release with 3 replicas:

```bash
helm upgrade web-app ./app-chart --set replicaCount=3
```

#### 💡 Command Breakdown (cmd-explained):
- `helm upgrade`: Modifies an already installed release with new chart files or updated values.
- `web-app`: The existing release to upgrade.
- `./app-chart`: The chart source directory.
- `--set replicaCount=3`: Dynamically overrides the `replicaCount` parameter in `values.yaml` for this release.

Expected output:

```text
Release "web-app" has been upgraded. Happy Helming!
NAME: web-app
LAST DEPLOYED: ...
STATUS: deployed
REVISION: 2
```

---

## 5. Check Pods After Upgrade

```bash
kubectl get pods
```

Expected output:

```text
NAME                        READY   STATUS    RESTARTS
web-app-app-aaaa            1/1     Running   0
web-app-app-bbbb            1/1     Running   0
web-app-app-cccc            1/1     Running   0
```

Three pods are now running.

---

## 6. install vs upgrade vs upgrade --install

```text
helm install    = fails if release already exists
helm upgrade    = fails if release does not exist
helm upgrade --install = installs if new, upgrades if exists
```

The safest command for CI/CD pipelines:

```bash
helm upgrade --install web-app ./app-chart
```

#### 💡 Command Breakdown (cmd-explained):
- `helm upgrade --install` (or `-i`): Idempotent release deployment command. If `web-app` does not exist in the cluster, it runs `helm install`; if it already exists, it executes `helm upgrade`. Ideal for automated CI/CD deployment jobs.

---

## 7. Uninstall

```bash
helm uninstall web-app
```

#### 💡 Command Breakdown (cmd-explained):
- `helm uninstall` (previously `helm delete`): Completely removes the release `web-app` and deletes all associated Kubernetes resources (Deployments, Services, ConfigMaps) managed by this release.

Expected output:

```text
release "web-app" uninstalled
```

---

## Key Learning

```text
REVISION: 1  = first install
REVISION: 2  = after first upgrade
REVISION: 3  = after second upgrade
```

Every install or upgrade creates a new revision. This enables rollback.

---

### 📚 Tech Jargons Demystified:
- **Release:** A running instance of a chart in a Kubernetes cluster. You can install the same chart multiple times with different release names (e.g., `web-dev`, `web-prod`).
- **Revision:** An incremental numeric version (1, 2, 3...) assigned to every state change of a release. Helm stores revision manifests as Kubernetes secrets.
- **Idempotency (`upgrade --install`):** The ability to run the deployment script repeatedly without error regardless of whether the application is being installed for the first time or updated.
- **Atomic Operation:** Deploying all resources together where any failure triggers a rollback, preventing half-deployed broken states.

---

## Reference

* **Helm install:** https://helm.sh/docs/helm/helm_install/
* **Helm upgrade:** https://helm.sh/docs/helm/helm_upgrade/


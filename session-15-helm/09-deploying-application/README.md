# Deploying an Application with Helm

```bash
helm install guestbook ./guestbook-chart
```

Put it all together. Deploy a complete application using a Helm chart you write from scratch.

---

## 1. What We Are Building

A simple guestbook web application with:

* A Deployment running nginx
* A Service exposing it on port 80
* A ConfigMap holding the app configuration

---

## 2. Create the Chart

```bash
mkdir -p guestbook-chart/templates
```

---

## 3. Chart.yaml

`guestbook-chart/Chart.yaml`:

```yaml
apiVersion: v2
name: guestbook-chart
description: A simple guestbook application
type: application
version: 0.1.0
appVersion: "1.0"
```

---

## 4. values.yaml

`guestbook-chart/values.yaml`:

```yaml
replicaCount: 1

image:
  repository: nginx
  tag: "1.24"

service:
  port: 80

config:
  welcomeMessage: "Welcome to the Guestbook!"
  appName: "My Guestbook"
```

---

## 5. templates/configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
data:
  welcome: {{ .Values.config.welcomeMessage | quote }}
  appName: {{ .Values.config.appName | quote }}
```

---

## 6. templates/deployment.yaml

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
        - name: guestbook
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.port }}
          envFrom:
            - configMapRef:
                name: {{ .Release.Name }}-config
```

---

## 7. templates/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-svc
spec:
  type: NodePort
  selector:
    app: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
      nodePort: 30080
```

---

## 8. Lint the Chart

```bash
helm lint guestbook-chart
```

#### 💡 Command Breakdown (cmd-explained):
- `helm lint`: Runs static analysis and syntax validation on the chart to identify structural errors, formatting issues, or missing required chart metadata before deployment.

Expected output:

```text
==> Linting guestbook-chart
1 chart(s) linted, 0 chart(s) failed
```

---

## 9. Render Templates Locally

```bash
helm template my-guestbook guestbook-chart
```

#### 💡 Command Breakdown (cmd-explained):
- `helm template`: Renders chart templates locally and prints the evaluated manifests to standard output without needing a cluster connection.
- `my-guestbook`: Test release name to substitute into `{{ .Release.Name }}`.

Check the output to ensure all `{{ }}` are replaced with real values.

---

## 10. Install

```bash
helm install my-guestbook guestbook-chart
```

#### 💡 Command Breakdown (cmd-explained):
- `helm install`: Installs the chart as a new release named `my-guestbook` into the target Kubernetes cluster.

Expected output:

```text
NAME: my-guestbook
LAST DEPLOYED: ...
STATUS: deployed
REVISION: 1
```

---

## 11. Verify

```bash
kubectl get pods
kubectl get services
kubectl get configmaps
```

#### 💡 Command Breakdown (cmd-explained):
- `kubectl get pods,services,configmaps`: Checks the status of the three distinct Kubernetes resources generated and deployed by the Helm chart.

Expected pods output:

```text
NAME                             READY   STATUS    RESTARTS
my-guestbook-app-xxxx            1/1     Running   0
```

---

## 12. Upgrade: Scale to 3 Replicas

```bash
helm upgrade my-guestbook guestbook-chart --set replicaCount=3
```

#### 💡 Command Breakdown (cmd-explained):
- `helm upgrade`: Updates release `my-guestbook`.
- `--set replicaCount=3`: Overrides `replicaCount` to scale the deployment from 1 to 3 pods in place.

```bash
kubectl get pods
```

Expected output:

```text
NAME                             READY   STATUS    RESTARTS
my-guestbook-app-aaaa            1/1     Running   0
my-guestbook-app-bbbb            1/1     Running   0
my-guestbook-app-cccc            1/1     Running   0
```

---

## 13. Check History

```bash
helm history my-guestbook
```

#### 💡 Command Breakdown (cmd-explained):
- `helm history my-guestbook`: Lists all revisions and descriptions for the release to verify the upgrade created Revision 2.

Expected output:

```text
REVISION   STATUS      DESCRIPTION
1          superseded  Install complete
2          deployed    Upgrade complete
```

---

## 14. Rollback

```bash
helm rollback my-guestbook 1
```

#### 💡 Command Breakdown (cmd-explained):
- `helm rollback my-guestbook 1`: Reverts the deployment back to Revision 1 (1 replica).

Expected output:

```text
Rollback was a success! Happy Helming!
```

---

## 15. Clean Up

```bash
helm uninstall my-guestbook
```

#### 💡 Command Breakdown (cmd-explained):
- `helm uninstall my-guestbook`: Completely purges the release and deletes the Deployment, Service, and ConfigMap simultaneously.

All resources (Deployment, Service, ConfigMap) are deleted automatically.

---

## Key Learning

```text
1. Write Chart.yaml   (metadata)
2. Write values.yaml  (defaults)
3. Write templates/   (Kubernetes YAML with {{ }})
4. helm lint          (check syntax)
5. helm template      (preview rendered YAML)
6. helm install       (deploy to cluster)
7. helm upgrade       (update configuration)
8. helm rollback      (revert if broken)
9. helm uninstall     (clean up)
```

---

### 📚 Tech Jargons Demystified:
- **Linting (`helm lint`):** Static verification that checks chart structure, required YAML keys, and template syntax against Helm best practices.
- **NodePort Service:** A Kubernetes Service type that opens a high port (range 30000–32767) on all cluster nodes, providing direct external access without an external cloud load balancer.
- **Template Pipeline (`| quote`):** A formatting filter that ensures string values with numbers or special characters are safely quoted in the final YAML output.
- **Unified Lifecycle Management:** Helm treats the entire multi-manifest application (Deployment, Service, ConfigMap) as a single logical unit that can be installed, updated, rolled back, or deleted together.

---

## Reference

* **Helm best practices:** https://helm.sh/docs/chart_best_practices/


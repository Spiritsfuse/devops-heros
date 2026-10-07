# Chart Structure

```text
my-chart/
  Chart.yaml        <-- who is this chart?
  values.yaml       <-- what are the defaults?
  templates/        <-- what does it create?
    deployment.yaml
    service.yaml
    _helpers.tpl    <-- reusable template snippets
    NOTES.txt       <-- message shown after install
```

---

## 1. Create the Example Chart

```bash
mkdir -p simple-chart/templates
```

#### 💡 Command Breakdown (cmd-explained):
* `mkdir -p simple-chart/templates`: Flag `-p` (`--parents`) creates both the parent `simple-chart` directory and its nested child `templates/` directory in a single command without failing if they already exist.

---

## 2. Chart.yaml

Create `simple-chart/Chart.yaml`:

```yaml
apiVersion: v2
name: simple-chart
description: A simple Helm chart example
type: application
version: 0.1.0
appVersion: "1.0"
```

* `version`: the version of this chart itself
* `appVersion`: the version of the application inside

---

## 3. values.yaml

Create `simple-chart/values.yaml`:

```yaml
replicaCount: 1
image:
  repository: nginx
  tag: latest
service:
  port: 80
```

These are the default values. You can override them at install time.

---

## 4. templates/deployment.yaml

Create `simple-chart/templates/deployment.yaml`:

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
          ports:
            - containerPort: {{ .Values.service.port }}
```

* `{{ .Release.Name }}` = the name you give at `helm install`
* `{{ .Values.replicaCount }}` = value from `values.yaml`

---

## 5. templates/service.yaml

Create `simple-chart/templates/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-svc
spec:
  selector:
    app: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
```

---

## 6. Render the Chart Locally

```bash
helm template my-release simple-chart
```

#### 💡 Command Breakdown (cmd-explained):
* `helm template my-release simple-chart`: Parses the Go template directives and substitutes the namespace release name (`my-release`) and values, outputting the rendered Deployment and Service YAML to verify variable substitution.

Expected output (partial):

```text
---
# Source: simple-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-release-app
spec:
  replicas: 1
...
```

Notice `my-release-app` - Helm replaced `{{ .Release.Name }}` with `my-release`.

---

## 7. Install the Chart

```bash
helm install my-release simple-chart
```

#### 💡 Command Breakdown (cmd-explained):
* `helm install my-release simple-chart`: Instantiates the chart on the cluster, deploying the Nginx container and its ClusterIP service.

Check:

```bash
kubectl get pods
kubectl get services
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pods,services`: Confirms that the pod `my-release-app-...` and service `my-release-svc` are running.

---

## Clean Up

```bash
helm uninstall my-release
```

#### 💡 Command Breakdown (cmd-explained):
* `helm uninstall my-release`: Removes the release, terminating the deployment and tearing down the service endpoint.

---

## Key Learning

```text
Chart.yaml    = chart metadata (name, version)
values.yaml   = default values for templates
templates/    = Kubernetes YAML with {{ variables }}
```

---

## Reference

* **Chart file structure:** https://helm.sh/docs/topics/charts/#the-chart-file-structure

---

### 📚 Tech Jargons Demystified:
* **The Dot Scope (`.`):** In Go templating, `.` represents the current root scope. `{{ .Values }}` accesses user-supplied variables, `{{ .Release }}` accesses release metadata, and `{{ .Chart }}` accesses `Chart.yaml`.
* **Built-in Objects:**
  * `.Release.Name`: The release name chosen at install time.
  * `.Release.Namespace`: The Kubernetes namespace where the release is installed.
  * `.Chart.Version`: The chart package version specified in `Chart.yaml`.
* **apiVersion: v2:** Specifies that the chart format is Helm 3 compatible (v1 was used in legacy Helm 2).
* **SemVer (Semantic Versioning):** `MAJOR.MINOR.PATCH` format (e.g. `0.1.0`). Helm charts strictly require semantic versioning for chart version tracking and dependency resolution.

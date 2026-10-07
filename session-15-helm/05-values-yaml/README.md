# `values.yaml`

```yaml
replicaCount: 1
image:
  repository: nginx
  tag: latest
```

`values.yaml` holds the default configuration for a chart.

---

## 1. Why values.yaml?

Without values.yaml, every configuration is hardcoded inside templates:

```yaml
# templates/deployment.yaml
replicas: 1                   # hardcoded
image: nginx:latest           # hardcoded
```

With values.yaml, the template becomes flexible:

```yaml
# templates/deployment.yaml
replicas: {{ .Values.replicaCount }}
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

---

## 2. Create values.yaml

```yaml
replicaCount: 1

image:
  repository: nginx
  tag: latest

service:
  port: 80

app:
  name: demo-app
```

---

## 3. Use Values in Templates

```yaml
# templates/deployment.yaml
metadata:
  name: {{ .Values.app.name }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

---

## 4. Override Values at Install Time

**Option A: Override with --set flag**

```bash
helm install my-app ./chart --set replicaCount=3
```

#### 💡 Command Breakdown (cmd-explained):
* `helm install ... --set replicaCount=3`: Modifies values on the fly without editing files. Translates `replicaCount=3` into an in-memory dictionary update replacing the default value `1`.

**Option B: Override with a separate values file**

Create `values-prod.yaml`:

```yaml
replicaCount: 5
image:
  tag: v2.0.0
```

Install using it:

```bash
helm install my-app ./chart -f values-prod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `-f values-prod.yaml`: Flag `-f` (`--values`) merges an external YAML file on top of `values.yaml`. Any key present in `values-prod.yaml` overrides the default; keys omitted retain their default values.

---

## 5. Check What Values Will Be Used

Render templates and check:

```bash
helm template my-app ./chart | grep "replicas:"
```

#### 💡 Command Breakdown (cmd-explained):
* `helm template my-app ./chart | grep "replicas:"`: Renders the chart locally and pipes the stdout through `grep` to quickly verify that the replica count matches the expected default.

Expected output:

```text
  replicas: 1
```

Now with override:

```bash
helm template my-app ./chart --set replicaCount=3 | grep "replicas:"
```

#### 💡 Command Breakdown (cmd-explained):
* `helm template ... --set replicaCount=3`: Confirms that CLI `--set` overrides successfully propagate into the rendered manifest before deploying to the cluster.

Expected output:

```text
  replicas: 3
```

To inspect currently deployed values on a live cluster release:

```bash
helm get values my-app
```

#### 💡 Command Breakdown (cmd-explained):
* `helm get values <release>`: Retrieves user-supplied override values stored inside the cluster release secret. Add `--all` to print the full computed merge of defaults and overrides.

---

## 6. Priority of Values

```text
Lowest priority   -->   Highest priority

values.yaml  ->  -f file  ->  --set flag
```

`--set` always wins.

---

## Key Learning

```text
values.yaml = the default configuration
-f file     = environment-specific overrides (dev, prod)
--set       = quick one-off overrides (avoid in production)
```

---

## Reference

* **Values and templates:** https://helm.sh/docs/chart_template_guide/values_files/

---

### 📚 Tech Jargons Demystified:
* **Values Precedence:** Values merge following a strict hierarchy: `values.yaml` (chart base) $\rightarrow$ multiple `-f file1.yaml -f file2.yaml` (ordered left to right) $\rightarrow$ `--set key=val` (highest priority).
* **`--set` Variations:**
  * `--set key=value`: Auto-casts types (e.g. `true` to boolean, `123` to int).
  * `--set-string key=value`: Forces the value to be parsed as a string, avoiding scientific notation bugs on phone numbers or hashes.
  * `--set-file key=/path/to/file`: Reads a file's entire content into a value (useful for injecting certificates or licenses).
* **Configuration Drift in Production:** In GitOps / production environments, storing overrides in tracked files (`values-staging.yaml`, `values-prod.yaml`) in Git is strongly preferred over CLI `--set` flags to ensure an audit trail.

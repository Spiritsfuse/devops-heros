# ConfigMap — Decoupling Plain-Text Configuration from Container Images

## Why Do We Need ConfigMap?

### The Problem: Configuration Baked Into Docker Images
Imagine you write a Python app and hardcode inside it:
```python
LOG_LEVEL = "DEBUG"
PORT = 5000
DATABASE_HOST = "localhost"
```
You build a Docker image and push it to your registry. Now you want to deploy the same app to Production. In Production:
* `LOG_LEVEL` should be `INFO` (not `DEBUG`)
* `DATABASE_HOST` should be `prod-db.internal` (not `localhost`)

If configuration is baked into the image, you must **rebuild the Docker image every time a config value changes**. That violates the 12-Factor App principle:
> **Your code must be identical across all environments. Only the configuration changes.**

### The Solution: ConfigMap
A `ConfigMap` stores plain-text key-value pairs outside your container image. Your application reads them as environment variables or volume-mounted config files at runtime.

```text
WITHOUT ConfigMap:                    WITH ConfigMap:
--------------------                  --------------------
Image: v1 (LOG=DEBUG)                 Image: v1 (no hardcoded config)
Image: v2 (LOG=INFO)                       |
Image: v3 (PORT=8080)            ConfigMap: LOG=INFO, PORT=5000
                                       |
                                   Same image deployed everywhere!
```

---

## Important Points

* ConfigMaps are for **non-sensitive** data only (log levels, port numbers, feature flags, API base URLs).
* Never store passwords, tokens, or certificates in a ConfigMap.
* ConfigMaps can be consumed as **environment variables** (`envFrom`) or **mounted as files** inside a container.
* Updating a ConfigMap does NOT automatically restart your pods. Pods must be restarted to pick up new values (unless using a volume mount with live reload).
* ConfigMaps have a size limit of **1 MiB**.

---

## Real-World Use Cases
* Storing `LOG_LEVEL`, `ENVIRONMENT` (dev/staging/prod), `CACHE_TTL`, `MAX_CONNECTIONS` for a microservice.
* Mounting an entire Nginx `nginx.conf` file into a pod via a ConfigMap volume.
* Passing feature-flag toggles (`FEATURE_DARK_MODE: "true"`) without rebuilding images.

---

## Code

### configmap/app-config.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: yatri-app-config
  labels:
    app: yatri-backend
data:
  ENVIRONMENT: "production"
  LOG_LEVEL: "INFO"
  PORT: "5000"
  DEFAULT_CURRENCY: "INR"
  MAX_BOOKING_DAYS: "30"
```

### Apply and Inspect
```bash
kubectl apply -f configmap/app-config.yaml
kubectl get configmap yatri-app-config
kubectl describe configmap yatri-app-config
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f configmap/app-config.yaml`: Submits the ConfigMap manifest to the API server, saving the plain-text key-value configuration into etcd.
* `kubectl get configmap <name>`: Lists the specified ConfigMap, showing the number of data entries (`DATA: 5`) and age. Alias `cm` can be used (`kubectl get cm`).
* `kubectl describe configmap <name>`: Dumps the complete internal breakdown of all stored configuration keys, values, and object metadata.

Expected Output:
```text
NAME               DATA   AGE
yatri-app-config   5      8s

Name:         yatri-app-config
Data
====
DEFAULT_CURRENCY:  INR
ENVIRONMENT:       production
LOG_LEVEL:         INFO
MAX_BOOKING_DAYS:  30
PORT:              5000
```

### Reading a ConfigMap Value Live
```bash
kubectl get configmap yatri-app-config -o jsonpath='{.data.LOG_LEVEL}'
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get configmap ...`: Retrieves the ConfigMap resource.
* `-o jsonpath='{.data.LOG_LEVEL}'`: Uses JSONPath query syntax to directly extract and print the exact value assigned to the `LOG_LEVEL` key (`INFO`) without parsing surrounding YAML/JSON metadata.

Output:
```text
INFO
```

### Cleanup
```bash
kubectl delete configmap yatri-app-config
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl delete configmap <name>`: Removes the ConfigMap from the cluster. Note that if active pods are currently referencing this ConfigMap via `configMapKeyRef` and restart, they will enter `CreateContainerConfigError` status until recreated.

---

### 📚 Tech Jargons Demystified:
* **ConfigMap:** A Kubernetes API object used to store non-confidential data in key-value pairs. Pods can consume ConfigMaps as environment variables, command-line arguments, or as configuration files in a volume.
* **12-Factor App (III. Config):** An industry software methodology stating that an application's configuration should be strictly separated from code, allowing the exact same build artifact/container image to run in dev, test, and production.
* **envFrom vs valueFrom:**
  * `envFrom`: Injects *all* key-value pairs from a ConfigMap as individual container environment variables at once.
  * `valueFrom.configMapKeyRef`: Selectively pulls a *single* specific key from the ConfigMap into an environment variable.
* **Immutable ConfigMap:** Setting `immutable: true` prevents accidental modifications to the ConfigMap in etcd and reduces load on the API server by eliminating automatic watch polling.

# What is Helm?

```text
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f configmap.yaml
...
```

That is what you do without Helm. For every environment.

> "Helm is the package manager for Kubernetes."

---

## 1. The Problem Helm Solves

Imagine you need to deploy the same application to three environments:

```text
Dev        Staging      Production
1 replica  2 replicas   10 replicas
small CPU  medium CPU   large CPU
```

Without Helm, you write three separate sets of YAML files. If you change one setting, you update three files manually.

With Helm, you write **one chart** and pass different values.

---

## 2. What is a Helm Chart?

A Helm Chart is a packaged collection of Kubernetes YAML files with variables.

```text
my-chart/
  Chart.yaml       <-- metadata about the chart
  values.yaml      <-- default variables
  templates/       <-- YAML files with {{ variables }}
```

Think of a chart like a **recipe**. The recipe stays the same. You decide the ingredients (values).

---

## 3. Install Helm

Run:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### 💡 Command Breakdown (cmd-explained):
* `curl ... | bash`: Downloads the official cross-platform installation script which automatically detects client OS architecture, fetches the latest Helm 3 release binary from GitHub releases, and installs it into `/usr/local/bin/helm`.

Verify:

```bash
helm version
```

#### 💡 Command Breakdown (cmd-explained):
* `helm version`: Checks the installed client version (e.g. `v3.15.0`) and Go runtime information. Helm 3 is client-only and requires no cluster-side server daemon.

Expected output:

```text
version.BuildInfo{Version:"v3.15.0", ...}
```

---

## 4. Your First Helm Command

List installed releases:

```bash
helm list
```

#### 💡 Command Breakdown (cmd-explained):
* `helm list` (alias `helm ls`): Queries the active namespace for Helm releases. On a fresh cluster, returns an empty table. Add `-A` (`--all-namespaces`) to inspect releases cluster-wide.

Expected output (empty cluster):

```text
NAME    NAMESPACE    REVISION    UPDATED    STATUS    CHART    APP VERSION
```

---

## 5. Install a Public Chart

Add the bitnami repository:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

#### 💡 Command Breakdown (cmd-explained):
* `helm repo add <name> <url>`: Registers a remote chart repository in your local client configuration (`~/.config/helm/repositories.yaml`), assigning it the local alias `bitnami`.
* `helm repo update`: Fetches the latest `index.yaml` catalog from all registered repositories, refreshing chart versions and checksums.

Install nginx:

```bash
helm install my-nginx bitnami/nginx
```

#### 💡 Command Breakdown (cmd-explained):
* `helm install <release-name> <repo/chart>`: Downloads chart `bitnami/nginx`, parses its templates using default `values.yaml`, sends the resulting manifests to `kube-apiserver`, and records Release `my-nginx` at Revision 1.

Expected output:

```text
NAME: my-nginx
LAST DEPLOYED: ...
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

Check what was created:

```bash
kubectl get pods
kubectl get services
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pods,services`: Verifies that Helm successfully provisioned the underlying Kubernetes Deployment, Pods, and Service declared in the chart.

---

## 6. Remove the Release

```bash
helm uninstall my-nginx
```

#### 💡 Command Breakdown (cmd-explained):
* `helm uninstall my-nginx`: Atomically terminates and deletes all Kubernetes objects associated with release `my-nginx` and purges the release tracking secret from etcd.

Expected output:

```text
release "my-nginx" uninstalled
```

All Kubernetes resources created by that release are now deleted.

---

## Key Concepts

```text
Chart    = the packaged template (recipe)
Release  = a running instance of a chart (cooked meal)
Values   = the variables you pass in (ingredients)
```

---

## Helm 2 vs Helm 3

```text
Helm 2: required a server pod called Tiller running in the cluster
        (security risk, required cluster-admin privileges)

Helm 3: no Tiller, client-only
        uses your kubeconfig permissions directly
        release state stored as Kubernetes Secrets
```

---

## Useful Commands

```bash
helm version
helm repo add <name> <url>
helm repo update
helm search repo <keyword>
helm install <release-name> <chart>
helm list
helm uninstall <release-name>
```

#### 💡 Command Breakdown (cmd-explained):
* `helm search repo <keyword>`: Searches your locally synced chart repository catalogs for matching packages (e.g. `helm search repo nginx` lists Bitnami Nginx, Ingress-Nginx, and Nginx-Mesh).

---

## Reference

* **Helm Documentation:** https://helm.sh/docs/
* **Helm GitHub:** https://github.com/helm/helm
* **Helm Charts:** https://helm.sh/docs/topics/charts/

---

### 📚 Tech Jargons Demystified:
* **Package Manager for Kubernetes:** Similar to `apt` for Debian or `npm` for Node.js, Helm bundles multi-resource microservices into a single distributable artifact with automated dependency and lifecycle management.
* **Helm Repository:** An HTTP server hosting an `index.yaml` metadata file and packaged chart tarballs (`.tgz`), facilitating versioned distribution of Kubernetes applications.
* **Artifact Hub:** The official CNCF open-source registry (artifacthub.io) for discovering public Helm charts, OCI artifacts, and Kubernetes plugins.
* **Release Name:** A unique user-chosen identifier (e.g. `my-nginx` or `production-database`) scoping an instance of a chart within a specific namespace.

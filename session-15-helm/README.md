# Session 15: Helm

Managing many Kubernetes YAML files across multiple environments leads to copy-paste errors and configuration drift.

Helm solves this. It is the package manager for Kubernetes.

---

## Why Helm?

Without Helm, deploying to three environments means three separate sets of YAML files. Change one value and you update three files manually.

With Helm, you write one chart. You pass different values for each environment.

---

## Topics Covered

| Folder | Topic |
|--------|-------|
| `01-what-is-helm/` | What is Helm, installing Helm, first commands |
| `02-helm-charts/` | What is a Chart, creating and installing charts |
| `03-chart-structure/` | Chart directory layout, Chart.yaml, values.yaml, templates |
| `04-chart-yaml/` | Chart.yaml fields, version vs appVersion |
| `05-values-yaml/` | Default values, overriding with -f and --set |
| `06-templates/` | Go template syntax, variables, conditionals |
| `07-install-upgrade/` | helm install, helm upgrade, revision history |
| `08-rollback/` | helm rollback, --atomic flag, auto rollback |
| `09-deploying-application/` | Full application deployment: lint, install, upgrade, rollback |
| `mini-project/` | Deploy the Notes App from scratch using Helm |

---

## Core Concepts

**Chart:** A packaged collection of Kubernetes YAML templates with variables. Think of it as a recipe.

**Release:** A running instance of a chart deployed to a cluster. Think of it as the cooked meal.

**Values:** The variables you pass to customize the chart. Think of them as the ingredients.

---

## Key Commands

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Create a new chart
helm create my-chart

# Render templates locally (no cluster needed)
helm template my-release ./my-chart

# Check chart for errors
helm lint ./my-chart

# Install a chart
helm install my-release ./my-chart

# Install with custom values
helm install my-release ./my-chart -f values-prod.yaml

# List all releases
helm list

# Upgrade a release
helm upgrade my-release ./my-chart --set replicaCount=3

# View release history
helm history my-release

# Rollback to a previous revision
helm rollback my-release 1

# Remove a release
helm uninstall my-release
```

#### 💡 Command Breakdown (cmd-explained):
* `curl ... | bash`: Fetches the official installation script and installs the standalone `helm` binary into `/usr/local/bin`.
* `helm create <name>`: Scaffolds a complete standard Helm chart directory structure including `Chart.yaml`, `values.yaml`, and sample Nginx deployment/service templates.
* `helm template <release> <chart>`: Dry-run template engine. Evaluates Go templates against values files and prints raw rendered Kubernetes YAML manifests to stdout without requiring an active Kubernetes cluster connection.
* `helm lint <chart>`: Static analysis tool. Scans the chart for syntax errors, missing mandatory fields, and template discrepancies according to Helm best practice standards.
* `helm install <release-name> <chart>`: Renders templates and sends them to `kube-apiserver`, creating release metadata stored as an encrypted Kubernetes Secret in the target namespace.
* `-f values-prod.yaml`: Flag `-f` (`--values`) merges an environment-specific YAML configuration file, overriding default values specified in `values.yaml`.
* `helm list` (alias `helm ls`): Lists all deployed releases across the namespace showing current revision number, update timestamp, status (`deployed`, `failed`), chart version, and app version.
* `helm upgrade <release> <chart> --set key=value`: Performs a delta upgrade. The `--set` flag overrides specific configuration variables directly from CLI at runtime.
* `helm history <release>`: Dumps the release audit trail showing past revision integers, deployment timestamps, statuses, and descriptive notes.
* `helm rollback <release> [revision]`: Reverts the cluster resources to the exact state captured by the specified previous revision number without needing to rebuild or reapply YAML.
* `helm uninstall <release>`: Purges all Kubernetes resources created by the release and deletes the release state secrets.

---

## Helm 2 vs Helm 3

```text
Helm 2: required Tiller (a server pod in the cluster)
        ran with cluster-admin privileges
        security risk

Helm 3: no Tiller
        client-only
        uses your kubeconfig permissions
        release state stored as Kubernetes Secrets
```

---

## Interview Preparation

**Beginner:**

Q: What is Helm?
A: Helm is a package manager for Kubernetes. It packages Kubernetes YAML files into parameterized charts that can be installed, upgraded, and rolled back with single commands.

Q: What is the difference between a Chart and a Release?
A: A Chart is the packaged template (the recipe). A Release is a running instance of that chart installed in a cluster (the cooked meal).

**Intermediate:**

Q: What is the difference between values.yaml and --set?
A: values.yaml holds the default configuration in version control. --set overrides individual values at runtime. In production pipelines, use separate values files (-f values-prod.yaml) so all configuration is auditable in Git.

Q: What does --atomic do?
A: During helm upgrade, --atomic auto-rolls back to the previous healthy revision if any pod fails readiness within the timeout period.

**Scenario-Based:**

Q: You run helm upgrade and it gets stuck in pending-upgrade state. What do you do?
A: Inspect helm secrets with kubectl get secrets -l owner=helm. Find the stuck pending revision secret and delete it. Then run helm rollback to the last healthy revision.

---

## Reference

* **Helm Documentation:** https://helm.sh/docs/
* **Helm Chart Template Guide:** https://helm.sh/docs/chart_template_guide/
* **Helm CLI Reference:** https://helm.sh/docs/helm/

---

### 📚 Tech Jargons Demystified:
* **Chart vs Release:**
  * **Chart:** A packaged bundle of YAML template files and metadata (`Chart.yaml`).
  * **Release:** A specific instantiated instance of a Chart running inside a Kubernetes cluster with its own unique release name and revision history.
* **Values File Precedence:** Values are merged with strict precedence: CLI `--set` overrides environment file `-f custom-values.yaml`, which overrides the chart's base `values.yaml`.
* **Helm 3 Release Secrets:** Helm 3 maintains release states inside Kubernetes Secrets named `sh.helm.release.v1.<release-name>.v<revision>` in the target namespace labeled with `owner: helm`.
* **Go Templating:** The syntax used in Helm templates (`{{ .Values.image.repository }}`) derived from Go's `text/template` library, supporting logic control (`if/else`, `range`, `with`) and pipeline functions (Sprig library: `quote`, `default`, `indent`).

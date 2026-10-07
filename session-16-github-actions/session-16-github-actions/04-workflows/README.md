# 04 - Workflows


## 1. What is a Workflow?

A workflow is an automated process defined using YAML.

Workflow files are stored inside:
```text
.github/workflows/
```

**Example Directory Structure:**
```text
.github/
└── workflows/
    └── workflow-demo.yml
```

---

## 2. Basic Workflow Structure

```yaml
name: Workflow Demo
on:
  workflow_dispatch:
jobs:
  workflow-demo:
    runs-on: ubuntu-latest
    steps:
      - name: Step 1
        run: echo "Hello"
```

#### 💡 Command Breakdown (cmd-explained):
- `echo "Hello"`: Prints `"Hello"` in the runner's execution console for Step 1.
- `name: Workflow Demo`: Human-friendly label rendered in GitHub's Actions navigation panel.
- `on: workflow_dispatch`: Configures the workflow to be triggered on-demand via the Web UI or GitHub CLI.
- `jobs.workflow-demo`: Top-level dictionary identifying a discrete job named `workflow-demo`.
- `steps:`: Sequential tasks executed within this job's dedicated VM container.

---

## 3. Workflow Name

```yaml
name: Workflow Demo
```
This is the name displayed in GitHub Actions.

---

## 4. Trigger

```yaml
on:
  workflow_dispatch:
```
Allows manual execution.

Other common triggers include:
```yaml
on:
  push:
```
and:
```yaml
on:
  pull_request:
```

---

## 5. Workflow Execution

```mermaid
flowchart LR
    A[Workflow] --> B[Job]
    B --> C[Step]
    C --> D[Command]
```

---

## 6. Expected Output

```text
Workflow started
Running application task
Running tests
Workflow completed
```

---

### 💡 Key Takeaway
A workflow defines:

> **WHEN** + **WHAT**

* **WHEN** = trigger
* **WHAT** = jobs and steps

---

### 📚 Tech Jargons Demystified:
- **Event Trigger (`on:`):** A specific activity (e.g. `push`, `pull_request`, `schedule`, `workflow_dispatch`) that instructs GitHub Actions to execute a workflow.
- **Workflow File Path:** Workflows must be saved inside `.github/workflows/` at the root of the repository in YAML (`.yml` or `.yaml`) syntax.
- **Step Isolation vs Job Isolation:** Multiple steps inside a single job run on the same virtual machine and can share files directly on disk; different jobs run on isolated machines and cannot share files unless using Artifacts or Caching.
- **Declarative YAML:** Defining infrastructure and execution steps as structured configuration data rather than procedural custom scripts.


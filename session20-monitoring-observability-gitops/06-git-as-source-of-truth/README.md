# 06 - Git as Source of Truth

This folder focuses on one important GitOps idea:

> Git stores what we WANT the system to look like.

---

# Source of Truth

Imagine:

```text
Git says:
replicas = 3
```

But Kubernetes currently has:

```text
replicas = 2
```

GitOps says:

```text
Desired state = 3
Actual state  = 2
```

A GitOps controller works to reconcile the difference.

---

# Git Repository Example

Inside:

```text
gitops-repo/
```

we have:

```text
gitops-repo/
|
|-- README.md
|
|-- app/
    |-- deployment.yaml
    |-- service.yaml
```

A real repository could look like:

```text
my-company-gitops/
|
|-- apps/
|   |-- payments/
|   |-- orders/
|   |-- users/
|
|-- environments/
    |-- dev/
    |-- staging/
    |-- production/
```

The exact structure is an engineering choice.

---

# Create a Git Repository

Inside `gitops-repo`:

```bash
cd gitops-repo
git init
```

#### 💡 Command Breakdown (`cmd-explained`):
- `cd gitops-repo`: Navigates your terminal's current working directory into the `gitops-repo` folder.
- `git init`: Initializes an empty Git version control repository. It creates a hidden `.git/` folder containing object databases, reference pointers (`refs/heads`), and configuration files.
- **Theory Connection**: Establishes this directory as the local **Source of Truth** repository.

Check:

```bash
git status
```

#### 💡 Command Breakdown (`cmd-explained`):
- `status`: Compares the files in your working directory against the Git staging index (`index`) and the latest commit (`HEAD`).
- Highlights untracked files in red (manifests waiting to be tracked by Git).

Add files:

```bash
git add .
```

#### 💡 Command Breakdown (`cmd-explained`):
- `add`: Stages changes from the working tree into the Git index.
- `.` (dot): Shorthand representing the current directory and all subdirectories recursively. Every YAML manifest in `app/` is now staged for snapshotting.

Commit:

```bash
git commit -m "Add session 20 application manifests"
```

#### 💡 Command Breakdown (`cmd-explained`):
- `commit`: Creates a permanent, immutable snapshot (commit object) in the Git DAG (Directed Acyclic Graph) containing the staged tree, author info, timestamp, and parent hash.
- `-m "..."` (or `--message`): Attaches an inline human-readable explanation of *what* change this commit introduces. Without `-m`, Git opens your default text editor (like vim or nano) to prompt for a message.
- **Theory Connection**: Locks in Version 1.0 of the **desired state** for the Kubernetes workload.

Expected shape:

```text
[main abc1234] Add session 20 application manifests
 2 files changed
```

The hash is different on every repository.

---

# Change the Desired State

Open:

```text
app/deployment.yaml
```

Change:

```yaml
replicas: 2
```

to:

```yaml
replicas: 3
```

Then:

```bash
git diff
```

#### 💡 Command Breakdown (`cmd-explained`):
- `diff`: Compares changes between your working tree and the staging index.
- Prefixes removed lines with `-` in red and added lines with `+` in green, clearly displaying the declarative replica intent changing from 2 to 3.

You should see a change similar to:

```diff
-  replicas: 2
+  replicas: 3
```

Commit it:

```bash
git add .
git commit -m "Scale application to three replicas"
```

#### 💡 Command Breakdown (`cmd-explained`):
- `git add .`: Stages the modified `deployment.yaml`.
- `git commit -m "..."`: Records the scale-out event into version control. In GitOps, scaling up or down is simply a Git commit, not an ad-hoc imperative terminal command!

---

# Why This Is Powerful

Now we have history:

```text
Commit 1
replicas = 2
     |
     v
Commit 2
replicas = 3
```

If the team asks:

> "Who changed the deployment?"

Git can answer.

If the team asks:

> "What changed?"

Git can show the diff.

---

# Important Distinction

Git is not the Kubernetes cluster.

```text
Git
 |
 +-- Desired state
 |
 v
Argo CD
 |
 v
Kubernetes
 |
 +-- Actual state
```

Argo CD connects the two.

---

# Practice

Why is Git useful as a source of truth?

Expected ideas:

```text
Version history
Review
Diff
Auditability
Collaboration
Rollback/reference point
```

---

### 📚 Tech Jargons Demystified:
- **Git Working Tree vs Index vs HEAD**:
  - **Working Tree**: The actual files on your filesystem you edit.
  - **Index (Staging Area)**: A binary cache file (`.git/index`) tracking what will go into the next commit.
  - **HEAD**: A symbolic reference pointing to the tip commit of your currently checked-out branch.
- **Commit Hash (SHA)**: A cryptographically calculated checksum (40-character hexadecimal string) ensuring content integrity; if even a single character in a YAML file changes, the hash changes completely.
- **Rollback via Revert**: Instead of logging into clusters to revert changes, running `git revert <commit-hash>` creates an inverse commit that undoes the bad deployment, triggering GitOps controllers to cleanly roll back the cluster.
- **Declarative vs Imperative**:
  - *Imperative*: Telling the system *how* to do something step-by-step (`kubectl scale --replicas=3`).
  - *Declarative*: Telling the system *what* the end state should be (`replicas: 3` in YAML), letting automated controllers handle the execution.

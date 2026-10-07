# GitHub Actions Introduction

```yaml
# .github/workflows/hello.yml
name: Hello World

on: push

jobs:
  say-hello:
    runs-on: ubuntu-latest
    steps:
      - name: Print message
        run: echo "Hello from GitHub Actions"
```

Push this file. GitHub runs it automatically.

---

## 1. What is GitHub Actions?

GitHub Actions is a built-in automation platform inside GitHub.

```text
Without GitHub Actions:
  Jenkins server (you maintain it)
  CircleCI (external service)
  GitLab CI (separate platform)

With GitHub Actions:
  YAML file in .github/workflows/
  GitHub runs it
  No server to maintain
```

---

## 2. How It Works

```text
1. You create a YAML file in .github/workflows/
2. You push code to GitHub
3. GitHub detects the trigger
4. GitHub finds a runner machine
5. Runner clones the repository
6. Runner executes each step
7. GitHub shows you the result
```

---

## 3. Your First Workflow

Create the directory:

```bash
mkdir -p .github/workflows
```

#### 💡 Command Breakdown (cmd-explained):
- `mkdir -p .github/workflows`: Creates the hidden directory `.github` and subfolder `workflows` if they don't exist (`-p` handles parent folder creation and avoids errors if already existing).

Create the file `.github/workflows/hello.yml`:

```yaml
name: Hello World

on: push

jobs:
  say-hello:
    runs-on: ubuntu-latest
    steps:
      - name: Print message
        run: echo "Hello from GitHub Actions"
```

Push it:

```bash
git add .github/
git commit -m "Add hello world workflow"
git push
```

#### 💡 Command Breakdown (cmd-explained):
- `git add .github/`: Stages the `.github` directory and workflow file into Git index.
- `git commit -m "Add hello world workflow"`: Records the staged changes as a new commit.
- `git push`: Transmits commits to the GitHub repository, which fires a push webhook triggering the `say-hello` job.

---

## 4. View the Run

Go to your GitHub repository.

Click the **Actions** tab.

You should see your workflow run. Click on it to view the logs.

Expected output in the step:

```text
Hello from GitHub Actions
```

---

## 5. Workflow File Location

```text
Repository root
    │
    └── .github/
            │
            └── workflows/
                    │
                    ├── build.yml
                    ├── test.yml
                    └── deploy.yml
```

GitHub reads all `.yml` files inside `.github/workflows/`.

---

## 6. Components at a Glance

```text
name:    = display name of the workflow
on:      = what triggers this workflow
jobs:    = list of jobs to run
  job-id:
    runs-on:  = which runner to use
    steps:    = list of steps
      - name: = display name of step
        run:  = shell command to run
```

---

## Key Learning

```text
GitHub Actions = automation built into GitHub
Workflow       = YAML file in .github/workflows/
Trigger        = on: push, pull_request, schedule
Job            = group of steps on one runner
Step           = single command or action
```

---

### 📚 Tech Jargons Demystified:
- **Webhook Trigger:** An automated HTTP POST payload sent by GitHub to its internal Actions engine whenever an event (like `git push`) occurs.
- **Workflow Run:** A single execution instance of a workflow responding to an event trigger.
- **Console Log Streaming:** Real-time terminal output captured from each step on the runner and viewable in the GitHub browser UI.
- **Managed Runner Service:** Zero-maintenance infrastructure where GitHub provisions, patches, networks, and tears down the runner machines automatically.

---

## Reference

* **GitHub Actions quickstart:** https://docs.github.com/en/actions/quickstart
* **GitHub Actions marketplace:** https://github.com/marketplace?type=actions


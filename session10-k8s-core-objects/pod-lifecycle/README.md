# Kubernetes Pod Lifecycle Lab

This lab demonstrates the major Pod lifecycle situations using small, independent YAML files.

## Recommended

1. Running
2. Pending
3. Init container
4. Readiness
5. Liveness
6. Startup probe
7. Succeeded
8. Failed
9. CrashLoopBackOff
10. ImagePullBackOff
11. Multi-container Pod
12. Graceful termination

## Start the live watch

Run this in Terminal 1:

```bash
kubectl get pods -w
```

Then apply examples from another terminal.

## Basic commands

Create:
```bash
kubectl apply -f 01-running.yaml
```

#### 💡 Command Breakdown (`cmd-explained`):
- `apply -f`: Submits the pod manifest to the kube-apiserver, initiating container scheduling.

Watch:
```bash
kubectl get pods -w
```

#### 💡 Command Breakdown (`cmd-explained`):
- `-w` (or `--watch`): Streams pod lifecycle events in real time (`Pending` -> `ContainerCreating` -> `Running`).

Detailed lifecycle:
```bash
kubectl describe pod lifecycle-running
```

#### 💡 Command Breakdown (`cmd-explained`):
- `describe pod`: Audits conditions (`Initialized`, `Ready`, `ContainersReady`, `PodScheduled`), probe states, restart counts, and chronological cluster events.

Logs:
```bash
kubectl logs lifecycle-running
```

#### 💡 Command Breakdown (`cmd-explained`):
- `logs`: Queries stdout/stderr streams emitted by the container.

Container state:
```bash
kubectl get pod lifecycle-running -o jsonpath='{.status.containerStatuses[0].state}'
```

#### 💡 Command Breakdown (`cmd-explained`):
- `-o jsonpath='...'`: Uses JSONPath expression syntax to surgically extract the exact container state (`running`, `waiting`, or `terminated`) without scrolling through pages of YAML.

Full YAML/status:
```bash
kubectl get pod lifecycle-running -o yaml
```

#### 💡 Command Breakdown (`cmd-explained`):
- `-o yaml`: Dumps the complete raw live object definition stored in etcd, including dynamic runtime status fields populated by the kubelet.

Delete:
```bash
kubectl delete pod lifecycle-running
```

#### 💡 Command Breakdown (`cmd-explained`):
- `delete pod`: Sends `SIGTERM` to the container and triggers the 30-second graceful termination countdown.

## Important note about STATUS

`kubectl get pods` may display values such as:

- Pending
- Running
- Completed
- Error
- CrashLoopBackOff
- ImagePullBackOff
- ContainerCreating
- Terminating

These are not all official Pod phases.

Official Pod phases are:

- Pending
- Running
- Succeeded
- Failed
- Unknown

Container states are:

- Waiting
- Running
- Terminated

## 1. Running

```bash
kubectl apply -f 01-running.yaml
kubectl get pod lifecycle-running
```

Expected:
```text
NAME                READY   STATUS    RESTARTS
lifecycle-running   1/1     Running   0
```

## 2. Pending

```bash
kubectl apply -f 02-pending.yaml
kubectl get pod lifecycle-pending
kubectl describe pod lifecycle-pending
```

This requests impossible CPU/memory resources, so on a normal small cluster it should remain Pending.

The exact message depends on the cluster.

## 3. Succeeded

```bash
kubectl apply -f 03-succeeded.yaml
kubectl get pod lifecycle-succeeded
kubectl logs lifecycle-succeeded
```

Expected status:
```text
Completed
```

Pod phase:
```text
Succeeded
```

## 4. Failed

```bash
kubectl apply -f 04-failed.yaml
kubectl get pod lifecycle-failed
kubectl logs lifecycle-failed
```

Expected status:
```text
Error
```

Pod phase:
```text
Failed
```

## 5. CrashLoopBackOff

```bash
kubectl apply -f 05-crashloopbackoff.yaml
kubectl get pod lifecycle-crashloop -w
```

The container starts, exits with code 1, gets restarted, and keeps failing.

Inspect:
```bash
kubectl describe pod lifecycle-crashloop
kubectl logs lifecycle-crashloop
kubectl logs lifecycle-crashloop --previous
```

#### 💡 Command Breakdown (`cmd-explained`):
- `kubectl describe pod ...`: Shows exit codes (e.g. `Exit Code: 1`) and the restart count backoff timer.
- `kubectl logs ...`: Prints logs from the *currently running* container instance.
- `--previous`: Fetches standard output and standard error from the **previous container instance before it crashed**. Essential for diagnosing segfaults or panics where the new container has just rebooted and overwritten memory logs!

## 6. ImagePullBackOff

```bash
kubectl apply -f 06-imagepullbackoff.yaml
kubectl get pod lifecycle-image-error
kubectl describe pod lifecycle-image-error
```

The image tag intentionally does not exist.

## 7. Readiness probe

```bash
kubectl apply -f 07-readiness.yaml
kubectl get pod lifecycle-readiness -w
```

Inspect:
```bash
kubectl describe pod lifecycle-readiness
```

Important teaching point:

```text
Running != Ready
```

Readiness answers:
"Should this Pod receive traffic?"

## 8. Liveness probe

```bash
kubectl apply -f 08-liveness.yaml
kubectl get pod lifecycle-liveness -w
```

The health file is removed after 20 seconds. The liveness probe then fails and Kubernetes restarts the container.

Watch:
```bash
kubectl get pod lifecycle-liveness -w
```

Look at:
```text
RESTARTS
```

## 9. Startup probe

```bash
kubectl apply -f 09-startup.yaml
kubectl get pod lifecycle-startup -w
```

The application intentionally takes 30 seconds to start.

The startup probe gives it time before normal health management takes over.

## 10. Init container

```bash
kubectl apply -f 10-init-container.yaml
kubectl get pod lifecycle-init -w
```

Inspect:
```bash
kubectl describe pod lifecycle-init
kubectl logs lifecycle-init -c setup
```

#### 💡 Command Breakdown (`cmd-explained`):
- `-c setup`: In pods with multiple containers or init containers, specifies the exact container name (`setup`) to inspect. Without `-c`, Kubernetes returns an error requiring you to choose which container's logs to view.

Teaching point:

```text
Init container runs first
        ↓
Init completes
        ↓
Main container starts
```

## 11. Multi-container Pod

```bash
kubectl apply -f 11-multi-container.yaml
kubectl get pod lifecycle-multi-container
```

Expected:
```text
2/2
```

View individual container logs:
```bash
kubectl logs lifecycle-multi-container -c app
kubectl logs lifecycle-multi-container -c sidecar
```

#### 💡 Command Breakdown (`cmd-explained`):
- `-c app` / `-c sidecar`: Targets individual containers sharing the pod's network namespace and localhost interface.

Teaching point:

```text
One Pod
  ├── app container
  └── sidecar container
```

## 12. Graceful termination

```bash
kubectl apply -f 12-termination.yaml
kubectl get pod lifecycle-termination
```

Then in another terminal:

```bash
kubectl delete pod lifecycle-termination
```

Watch:
```bash
kubectl get pod lifecycle-termination -w
```

The process handles SIGTERM, performs cleanup, and exits.

## Cleanup everything

```bash
kubectl delete -f .
```

If you want to remove only these lab Pods:

```bash
kubectl delete pod lifecycle-running lifecycle-pending lifecycle-succeeded lifecycle-failed lifecycle-crashloop lifecycle-image-error lifecycle-readiness lifecycle-liveness lifecycle-startup lifecycle-init lifecycle-multi-container lifecycle-termination
```

## Suggested teaching flow

Use:

```bash
kubectl get pods -w
```

while applying each YAML.

For every example ask students:

1. What state/status do you see?
2. Is the container running?
3. Is the Pod ready?
4. Did the container restart?
5. Why did this happen?
6. Which command would you use to debug it?

The three most useful debugging commands are:

```bash
kubectl get pod <pod>
kubectl describe pod <pod>
kubectl logs <pod>
```

---

### 📚 Tech Jargons Demystified:
- **CrashLoopBackOff**: A backoff algorithm where the kubelet restarts a crashing container with exponential delays (10s, 20s, 40s... up to 5 minutes) to avoid overloading node CPU and disk with crash loops.
- **ImagePullBackOff**: Occurs when the container runtime fails to pull an image (due to wrong image tag, missing registry credentials, or network errors) and exponentially delays retry attempts.
- **Pod Phase vs Container State**:
  - *Pod Phase*: High-level status (`Pending`, `Running`, `Succeeded`, `Failed`, `Unknown`).
  - *Container State*: Detailed process status inside the container (`Waiting`, `Running`, `Terminated`).
- **Grace Period (SIGTERM vs SIGKILL)**: When a pod is deleted, Kubernetes sends `SIGTERM` and waits `terminationGracePeriodSeconds` (default 30s) for connections to drain. If the container doesn't terminate within the grace period, the kernel forcibly kills it with `SIGKILL` (signal 9).

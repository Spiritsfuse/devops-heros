# `ImagePullBackOff`

```bash
ImagePullBackOff
```

---

## 1. Create The Broken Pod

```bash
kubectl apply -f broken-pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f broken-pod.yaml`: Deploys a pod referencing an invalid, non-existent Docker image tag (`nginx:this-image-does-not-exist`).

Check:

```bash
kubectl get pod image-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pod image-demo`: Observes status transition from `ContainerCreating` to `ErrImagePull`, and shortly afterward to `ImagePullBackOff`.

You may see:

```text
NAME         READY   STATUS             RESTARTS
image-demo   0/1     ErrImagePull       0
```

After some retries, you may see:

```text
NAME         READY   STATUS             RESTARTS
image-demo   0/1     ImagePullBackOff   0
```

---

## 2. What Does It Mean?

Kubernetes tried to download the image, but it could not.

Simple flow:

```text
Pod
 │
 ▼
Need container image
 │
 ▼
Kubernetes tries to pull image
 │
 ▼
Pull fails
 │
 ▼
Kubernetes retries
 │
 ▼
ImagePullBackOff
```

---

## 3. Describe The Pod

Run:

```bash
kubectl describe pod image-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl describe pod image-demo`: Checks the `Events:` log at the bottom. Kubelet prints the exact error response returned by the container registry (e.g. `Failed to pull image "nginx:...": rpc error: code = NotFound desc = failed to pull and unpack image ...: not found`).

Go to the **Events** section. You should see a message similar to:

```text
Failed to pull image
```

*(The exact message depends on the container runtime and cluster.)*

---

## 4. Check The Image Name

Our YAML contains:

```yaml
image: nginx:this-image-does-not-exist
```

That image tag does not exist. This is the problem.

---

## 5. Fix The Image

Delete the broken Pod:

```bash
kubectl delete pod image-demo
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl delete pod image-demo`: Deletes the failing pod to stop backoff pull retries.

Apply the fixed YAML:

```bash
kubectl apply -f fixed-pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f fixed-pod.yaml`: Applies the corrected manifest with a valid image tag (`nginx:alpine`). Kubelet successfully pulls the layers and launches the container.

Check:

```bash
kubectl get pod image-demo
```

Expected output:

```text
NAME         READY   STATUS
image-demo   1/1     Running
```

---

## 6. Other Possible Causes

`ImagePullBackOff` can happen because of:
* Wrong image name
* Wrong image tag
* Private registry authentication problem
* Registry unavailable
* Network problem
* Image does not exist

---

## Troubleshooting Flow

```text
ImagePullBackOff
       │
       ▼
kubectl describe pod
       │
       ▼
Look at Events
       │
       ▼
Check image name
       │
       ▼
Check image tag
       │
       ▼
Check registry access
       │
       ▼
      Fix
```

---

## Key Learning

Remember:

```text
CrashLoopBackOff
  = Container starts but keeps failing

ImagePullBackOff
  = Kubernetes cannot get the image
```

---

## Reference

* **Pull an Image from a Private Registry:**  
  https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

---

### 📚 Tech Jargons Demystified:
* **ErrImagePull vs ImagePullBackOff:**
  * `ErrImagePull`: The immediate error state returned on the first failed image download attempt.
  * `ImagePullBackOff`: The delayed retry state where kubelet waits progressively longer periods before attempting the pull again.
* **imagePullPolicy:**
  * `Always`: Kubelet queries the remote registry on every pod startup (default if tag is `:latest`).
  * `IfNotPresent`: Pulls only if the image does not already exist on the local worker node.
  * `Never`: Expects the image to be pre-loaded on the node; fails if absent.
* **imagePullSecrets:** Kubernetes secret specifying authentication credentials (username and access token) required to pull images from private registries (Docker Hub private repos, AWS ECR, GCP Artifact Registry).
* **Registry Rate Limiting:** Docker Hub imposes anonymous pull rate limits (100 pulls per 6 hours). Exceeding this triggers `ImagePullBackOff` with `toomanyrequests: You have reached your pull rate limit`.

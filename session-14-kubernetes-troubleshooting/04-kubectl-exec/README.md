# `kubectl exec`


```bash
kubectl exec
```

Think of it as:

> "Let me enter the container and check what is happening from inside."

---

## 1. Create the Pod

```bash
kubectl apply -f pod.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f pod.yaml`: Deploys the Nginx container workload to be used for container shell debugging.

Check:

```bash
kubectl get pod exec-demo
```

Expected output:

```text
NAME        READY   STATUS
exec-demo   1/1     Running
```

---

## 2. Open a Shell

Run:

```bash
kubectl exec -it exec-demo -- bash
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl exec`: Invokes the container runtime's exec mechanism through the kubelet over a SPDY/WebSocket stream.
* `-i` (`--stdin`): Passes stdin to the container, keeping user keyboard input open.
* `-t` (`--tty`): Allocates a pseudo-terminal/TTY inside the container so you get a command prompt, line wrapping, and interactive colored output.
* `--`: Positional parameter delimiter in bash/CLI. Tells kubectl: "Everything to the left is kubectl flags; everything to the right is the command to run inside the container".
* `bash`: Launches the Bourne-Again SHell inside the container (fallback to `sh` if the image is Alpine-based).

You should get a shell inside the container. You may see:

```text
root@exec-demo:/#
```

---

## 3. Check Files

Inside the container:

```bash
ls
```

Then:

```bash
ls /usr/share/nginx/html
```

You should see files related to the Nginx default page.

---

## 4. Check the Application

Run:

```bash
curl localhost
```

If `curl` is available, you should receive HTML output.

You can also try:

```bash
nginx -T
```

#### 💡 Command Breakdown (cmd-explained):
* `curl localhost`: Bypasses external network, Kubernetes Services, and ingress to test if the web application daemon is bound and listening on its loopback port.
* `nginx -T`: Validates and dumps the entire running Nginx configuration, including all include directives and virtual host blocks.

to inspect Nginx configuration.

---

## 5. Exit

```bash
exit
```

---

## 6. Run One Command Without Opening Shell

You don't always need an interactive shell.

For example:

```bash
kubectl exec exec-demo -- hostname
```

Or:

```bash
kubectl exec exec-demo -- ls /usr/share/nginx/html
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl exec <pod> -- <command>`: Non-interactive execution. Does not allocate a TTY (`-t` omitted), captures raw standard output directly to your local terminal, making it ideal for automation scripts.

---

## 7. Why Is `exec` Useful?

Suppose: **Service is not working**.

You can enter a Pod and test:

```bash
curl localhost
```

If localhost works:

```text
Application
     │
     ▼
  Working
```

Then you can investigate:
* Service
* DNS
* Network
* Port

This helps us narrow down the problem.

---

## Important

`kubectl exec` works with a running container.

If the container is constantly crashing, `exec` may not be useful because there may be no stable running container to enter.

For those cases, use:

```bash
kubectl logs
kubectl describe
kubectl debug
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl debug -it <pod-name> --image=nicolaka/netshoot`: Injects an ephemeral diagnostic container (packed with `tcpdump`, `curl`, `dig`, `ip`) into the running pod's network namespace without altering or restarting existing containers.

---

## Useful Commands

```bash
kubectl exec -it exec-demo -- bash
kubectl exec exec-demo -- hostname
kubectl exec exec-demo -- ls
kubectl exec exec-demo -- cat /etc/hosts
```

---

## Key Learning

Remember:

```text
kubectl exec
     │
     ▼
"Let me check from INSIDE the container."
```

Kubernetes documentation also recommends `kubectl exec` for running commands inside a container while debugging.

---

## Reference

* **Get a Shell to a Running Container:**  
  https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/

---

### 📚 Tech Jargons Demystified:
* **SPDY / WebSocket Connection:** The duplex streaming protocol used by `kubectl exec` to establish real-time terminal I/O streams between the client CLI, the API server, and node kubelet.
* **Double Dash (`--`) Syntax:** Standard POSIX argument separator. Without `--`, flags like `-l` or `-n` passed to the target container command could be misinterpreted by `kubectl` itself.
* **Distroless Images:** Highly secure container images containing only your compiled binary with zero shell (`/bin/sh` / `/bin/bash`) or OS utilities. You cannot use `kubectl exec` on distroless containers—instead, use `kubectl debug` with ephemeral containers.
* **Ephemeral Containers:** Lightweight temporary containers added to a running Pod via the `kubectl debug` API specifically designed for live interactive troubleshooting.

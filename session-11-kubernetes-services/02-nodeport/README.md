# NodePort Service — External Host-Level Cluster Access

## 1. What is a NodePort Service?
A `NodePort` service is the simplest native way to route external client traffic directly into your Kubernetes cluster.

When you configure `type: NodePort`, Kubernetes:
1. Allocates a dedicated high port from the range **`30000–32767`** (default pool).
2. Opens this exact port on **every single worker node** across the entire cluster.
3. Automatically creates a `ClusterIP` under the hood to route internal packets.

Any traffic sent to `http://<Any-Worker-Node-IP>:<NodePort>` is intercepted by `kube-proxy` on that node and forwarded to one of the backend pods, even if the destination pod is running on a different node.

---

## 2. Why Do We Need NodePort? (The Problem It Solves)

### The Problem: ClusterIP is Inaccessible from the Outside
`ClusterIP` uses internal private IPs (e.g., `10.96.0.0/12`) that are non-routable over the internet or office LAN. A user sitting at home or a client browser cannot reach a `ClusterIP`.

### The Solution: Expose a Dedicated Host Port
`NodePort` opens a port directly on the host machine's network interface. Anyone with network access to the node's IP address can access the workload on that static port.

```text
External Client / Web Browser
              |
              | Sends HTTP request to http://192.168.49.2:30080
              v
+-------------------------------------------------------------+
| Worker Node (IP: 192.168.49.2)                              |
|                                                             |
|   [Port 30080] (nodePort)                                   |
|         |                                                   |
|         v                                                   |
|   [Service Port: 80] (Internal ClusterIP: 10.96.210.44)     |
|         |                                                   |
|         +---------------------------+                       |
|         |                           |                       |
|         v                           v                       |
|  +--------------+            +--------------+               |
|  | Backend Pod 1|            | Backend Pod 2|               |
|  | 10.244.0.15  |            | 10.244.0.16  |               |
|  | (Port: 80)   |            | (Port: 80)   |               |
|  +--------------+            +--------------+               |
+-------------------------------------------------------------+
```

---

## 3. Think of It Like This: The Hotel Reception & Room Extension
* **The Hotel Building** = A physical or virtual Worker Node.
* **The Hotel Main Gate Guard (`nodePort: 30080`)** = The outside security gate that lets visitors enter from the street.
* **The Hotel Lobby Desk (`port: 80`)** = The internal reception desk coordinating guests.
* **The Guest's Room Door (`targetPort: 80`)** = The actual room where the guest is staying.

Even if you enter through North Wing Gate (`Node 1`) or South Wing Gate (`Node 2`), both gates direct you to the same guest rooms.

---

## 4. Where is NodePort Used in Production?
* **On-Premise and Bare-Metal Clusters:** When you do not have cloud APIs (AWS/GCP/Azure) to automatically provision a cloud load balancer.
* **Development and Staging Environments:** Quickly exposing applications on local clusters (Minikube, Kind, k3s, MicroK8s).
* **Exposing Ingress Controllers:** Ingress Controllers (like Traefik, HAProxy, or NGINX) are often exposed to physical hardware routers via a static `NodePort` (`30080` / `30443`).
* **Non-HTTP Protocols and Legacy Systems:** Exposing raw TCP/UDP services directly on known host ports.

---

## 5. Code Manifests & Field-by-Field Breakdown

### File: `app-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-nodeport
  labels:
    app: web-nodeport
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-nodeport
  template:
    metadata:
      labels:
        app: web-nodeport
    spec:
      containers:
        - name: web-server
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "100m"
              memory: "128Mi"
```

### File: `service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service-nodeport
  labels:
    app: web-nodeport
spec:
  type: NodePort
  selector:
    app: web-nodeport
  ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30080
      protocol: TCP
```

### Key Field Explanations:
* `spec.type: NodePort`: Declares the service as accessible on worker node IPs.
* `spec.ports[0].nodePort: 30080`: Manually sets the external port. If omitted, Kubernetes randomly assigns an available port from `30000–32767`.
* `spec.ports[0].port: 80`: The internal cluster port used by internal microservices.
* `spec.ports[0].targetPort: 80`: The container port where Nginx listens.

---

## 6. How to Run and Deploy

### Step 1: Apply the Deployment
```bash
kubectl apply -f 02-nodeport/app-deployment.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl`: The Kubernetes Command-Line Interface used to communicate with the control plane's `kube-apiserver`.
* `apply`: Declarative management command. Compares your YAML configuration with the live cluster state and applies differences without requiring pod restarts if specifications haven't changed.
* `-f 02-nodeport/app-deployment.yaml`: Flag `-f` (filename/filepath) tells kubectl the path to the manifest file defining the 2-replica Nginx Deployment.

Check pod status:
```bash
kubectl get pods -l app=web-nodeport -o wide
```

#### 💡 Command Breakdown (cmd-explained):
* `get pods`: Queries the API server for all running pod objects in the current namespace.
* `-l app=web-nodeport`: Filter by label (`-l` / `--selector`). Only returns pods matching the key-value pair `app=web-nodeport`, filtering out unrelated workloads.
* `-o wide`: Output formatting flag. Extends the default table to show essential diagnostic network details: Pod IP (`10.244.x.x`), host node name (`minikube` / `worker-1`), and readiness gate status.

Expected Output:
```text
NAME                                READY   STATUS    RESTARTS   AGE   IP            NODE
web-app-nodeport-77df98f8d9-6m2qp   1/1     Running   0          14s   10.244.0.20   minikube
web-app-nodeport-77df98f8d9-v9z8k   1/1     Running   0          14s   10.244.0.21   minikube
```

### Step 2: Apply the NodePort Service
```bash
kubectl apply -f 02-nodeport/service.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `apply -f 02-nodeport/service.yaml`: Creates or updates the `Service` of `type: NodePort`. Kube-apiserver instructs all kube-proxy instances across the cluster to listen on port `30080`.

Verify the service and the port mapping:
```bash
kubectl get svc web-service-nodeport
```

#### 💡 Command Breakdown (cmd-explained):
* `get svc`: Lists Service resources (`svc` is the canonical shorthand alias for `services`).
* `web-service-nodeport`: Limits output to this specific service name, displaying its type (`NodePort`), allocated virtual `ClusterIP`, and port mapping tuple (`80:30080/TCP`).

Expected Output:
```text
NAME                   TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
web-service-nodeport   NodePort   10.96.210.44    <none>        80:30080/TCP   10s
```
Notice the syntax `80:30080/TCP`:
* `80` = Internal Cluster Port
* `30080` = External NodePort

---

## 7. How to Check Website Traffic on NodePort

### Method A: Direct Access via Node IP (Standard Kubernetes / Docker Desktop)
Find your worker node IP:
```bash
kubectl get nodes -o wide
```

#### 💡 Command Breakdown (cmd-explained):
* `get nodes -o wide`: Lists all physical/virtual machines in your cluster with their Internal-IP, External-IP, OS image, and kernel version. The Internal-IP is the address you hit with your `nodePort` (`http://<Node-IP>:30080`).

Send a request using curl or open in your browser:
```bash
curl http://localhost:30080
```
Or with Minikube:
```bash
curl http://$(minikube ip):30080
```

#### 💡 Command Breakdown (cmd-explained):
* `curl http://localhost:30080`: Sends an HTTP GET request to localhost on port 30080 (works if using Docker Desktop or Kind with port mappings configured).
* `$(minikube ip)`: Command substitution in Bash/Zsh. Executes `minikube ip` first, retrieves the VM or container IP (e.g., `192.168.49.2`), and injects it dynamically into the curl URL.

### Method B: Minikube Service Tunnel (macOS / Docker driver)
On macOS with Docker driver, the VM IP is inside a private network bridge. Minikube provides a helper command to open a live browser session:
```bash
minikube service web-service-nodeport
```
Or to retrieve the direct reachable URL:
```bash
minikube service web-service-nodeport --url
```

#### 💡 Command Breakdown (cmd-explained):
* `minikube service <svc-name>`: Native Minikube helper that resolves the routing bridge and launches your default operating system browser directly pointed at the active NodePort endpoint.
* `--url`: Suppresses opening the browser window and prints just the raw HTTP/HTTPS URL string to stdout (ideal for shell scripts or piping to `curl`).

### Expected Output in Browser / Terminal:
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and working.</p>
...
</html>
```

---

## 8. Important Limitations of NodePort

1. **Port Range Constraints:** Limited to ports `30000–32767` by default. You cannot expose standard port `80` or `443` directly without custom API server flags.
2. **One Service Per Port:** Port numbers cannot be shared. If Service A uses `30080`, Service B cannot use `30080`.
3. **No Automatic DNS / High Availability:** If a worker node goes down, clients connecting to that specific node IP experience downtime unless an external load balancer balances traffic across all node IPs.
4. **Security Exposure:** Opens ports across all nodes in the cluster, requiring strict firewall / Security Group management.

---

## 9. Cleanup
```bash
kubectl delete -f 02-nodeport/service.yaml
kubectl delete -f 02-nodeport/app-deployment.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl delete -f <file>`: Tears down all objects declared in the YAML file. Kube-proxy removes iptables/IPVS routing rules for port 30080, and the replica pods are gracefully terminated.

---

### 📚 Tech Jargons Demystified:
* **NodePort:** A service type allocating a static port from `30000-32767` on every node's external IP interface, allowing outside traffic to enter the cluster without a cloud load balancer.
* **Port vs TargetPort vs NodePort:**
  * `nodePort`: The external port opened on every cluster worker node (e.g., `30080`).
  * `port`: The internal port inside the cluster where other pods reach the Service virtual IP (e.g., `80`).
  * `targetPort`: The actual container listening port on the backend Pod (e.g., `80`).
* **externalTrafficPolicy (Cluster vs Local):**
  * `Cluster` (default): Traffic arriving at any node can be forwarded across the overlay network to a pod on another node (incurs a network hop and hides client source IP via SNAT).
  * `Local`: Traffic is only routed to pods on the node receiving the request. Preserves client source IP, but packets are dropped if that node has no matching pods.
* **kube-proxy:** The network proxy running on each node that maintains iptables/IPVS rules, mapping NodePort and ClusterIP traffic to target Pod IPs.

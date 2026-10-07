# Ingress — One Entry Point for All Your Microservices

## Why Do We Need Ingress?

### The Problem: One Load Balancer Per Service = Expensive Chaos

Imagine your application has 5 microservices: Frontend, Backend API, Auth Service, Payment Service, and Admin Dashboard. Without Ingress, you need a separate `LoadBalancer` service for each one:

```text
Without Ingress:
  Frontend     -> AWS Load Balancer 1 ($25/month)
  Backend API  -> AWS Load Balancer 2 ($25/month)
  Auth         -> AWS Load Balancer 3 ($25/month)
  Payment      -> AWS Load Balancer 4 ($25/month)
  Admin        -> AWS Load Balancer 5 ($25/month)
  Total: $125/month just for load balancers
```

Users also get ugly non-standard ports and URLs like `http://3.15.22.100:30080`. There is no SSL/TLS termination, no centralized routing, and no ability to do host-based routing like `api.myapp.com` vs `myapp.com`.

### The Solution: Ingress Controller + Ingress Rules

An **Ingress Controller** (e.g., NGINX Ingress Controller) is a single pod running a reverse proxy. You deploy **one** `LoadBalancer` Service pointing to it. All routing logic is declared as `Ingress` YAML rules.

```text
With Ingress:
  1 AWS Load Balancer ($25/month)
       |
  NGINX Ingress Controller
       |
       +-- yatri.local/         -> Frontend ClusterIP Service
       +-- yatri.local/api/*    -> Backend API ClusterIP Service
```

```text
Public Internet
      |
      | https://yatri.local (Port 80/443)
      v
+------------------------------------------+
|   NGINX Ingress Controller Pod           |
|   (Layer 7 HTTP Reverse Proxy)           |
+------------------------------------------+
      |                        |
      | Path: /                | Path: /api/*
      v                        v
+----------------+     +---------------------+
| Frontend Svc   |     | Backend API Svc      |
| (ClusterIP)    |     | (ClusterIP)          |
+----------------+     +---------------------+
```

---

## Important Points

* An `Ingress` resource is **just a routing rule definition**. It does nothing on its own. You MUST have an **Ingress Controller** installed in your cluster (e.g., `ingress-nginx`).
* Ingress operates at **Layer 7 (HTTP/HTTPS)**. It can route based on hostnames (`api.shop.com`) and URL paths (`/orders`, `/users`).
* Ingress supports **TLS/HTTPS termination**: you configure your SSL certificate once in Ingress, and all backend services communicate over plain HTTP internally. This is the standard pattern.
* On Minikube, enable the addon: `minikube addons enable ingress`.
* On AWS EKS, install `ingress-nginx` via Helm and one AWS NLB is automatically provisioned for it.

---

## Real-World Use Cases
* Routing `app.company.com` to the frontend and `api.company.com` to the backend API — from a single public IP.
* SSL/TLS termination: attaching a certificate to `https://myapp.com` without modifying any application code.
* Canary deployments: routing 10% of `/api` traffic to a `v2` service and 90% to `v1`.
* Rate limiting, authentication headers, and CORS rules applied centrally via Ingress annotations.

---

## Code

### ingress/ingress-routes.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: yatri-ingress
  labels:
    app: yatri-app
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: yatri.local
      http:
        paths:
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: yatri-backend-service
                port:
                  number: 80
          - path: /
            pathType: Prefix
            backend:
              service:
                name: yatri-frontend-service
                port:
                  number: 80
```

### Apply and Inspect
```bash
kubectl apply -f ingress/ingress-routes.yaml
kubectl get ingress yatri-ingress
kubectl describe ingress yatri-ingress
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f ingress/ingress-routes.yaml`: Submits the Ingress routing manifest. The active Ingress Controller (e.g. `ingress-nginx`) detects this resource via its API watch loop and dynamically reloads its Nginx routing table without restarting.
* `kubectl get ingress <name>`: Summarizes the Ingress rule, displaying the ingress class (`nginx`), virtual hosts (`yatri.local`), and the bound gateway address/load balancer IP.
* `kubectl describe ingress <name>`: Lists detailed path mappings, backend service associations, TLS configuration, and recent sync events from the Ingress Controller.

Expected Output:
```text
NAME            CLASS   HOSTS        ADDRESS        PORTS   AGE
yatri-ingress   nginx   yatri.local  192.168.49.2   80      12s
```

---

## Hands-on: Host-Based Routing and TLS/HTTPS Termination

### Step 1: Generate a Self-Signed TLS Certificate
To secure your Ingress with HTTPS without paying a third-party certificate authority in local testing, create a local certificate pair:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=campus.local/O=CampusDevOps"
```

#### 💡 Command Breakdown (cmd-explained):
* `openssl req`: CLI tool for generating PKCS#10 Certificate Signing Requests and generating X.509 self-signed certificates.
* `-x509`: Directs OpenSSL to output a self-signed root certificate rather than a signing request.
* `-nodes`: Short for "no DES". Generates the private key without encrypting it with a passphrase, allowing automated container servers (Nginx) to read it without manual password prompts during restart.
* `-days 365`: Sets the validity duration of the certificate to 1 year.
* `-newkey rsa:2048`: Generates a new 2048-bit RSA private key.
* `-keyout tls.key`: The destination file path for the newly generated private key.
* `-out tls.crt`: The destination file path for the signed public certificate.
* `-subj "/CN=campus.local/O=CampusDevOps"`: Sets the X.500 Distinguished Name subject directly from CLI. `CN` (Common Name) defines the primary FQDN (`campus.local`), and `O` defines the Organization.

### Step 2: Create a Kubernetes TLS Secret
Store the public certificate and private key inside Kubernetes as a `kubernetes.io/tls` Secret:

```bash
kubectl create secret tls campus-tls-cert \
  --cert=tls.crt \
  --key=tls.key
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl create secret tls <name>`: Imperative subcommand specifically formatting secrets for HTTPS/TLS endpoints (type `kubernetes.io/tls`).
* `--cert=tls.crt`: Specifies the path to the public SSL/TLS certificate.
* `--key=tls.key`: Specifies the path to the private key.

Verify secret creation:
```bash
kubectl get secret campus-tls-cert
```

#### 💡 Command Breakdown (cmd-explained):
* `get secret campus-tls-cert`: Verifies secret storage, displaying `DATA: 2` (corresponding to the `tls.crt` and `tls.key` base64 entries).

Expected Output:
```text
NAME              TYPE                DATA   AGE
campus-tls-cert   kubernetes.io/tls   2      5s
```

### Step 3: Apply the Ingress with TLS and Multi-Host Rules
Inspect `03-ingress/ingress-tls.yaml` and apply it:

```bash
kubectl apply -f 03-ingress/ingress-tls.yaml
```

Inspect the applied Ingress:
```bash
kubectl get ingress campus-ingress-tls
```

Expected Output:
```text
NAME                 CLASS   HOSTS                                  ADDRESS        PORTS     AGE
campus-ingress-tls   nginx   portal.campus.local,api.campus.local   192.168.49.2   80, 443   10s
```

Notice `PORTS` shows `80, 443`, confirming both HTTP and HTTPS are active.

### Step 4: Test Host-Based and TLS Routing with curl
Map the local domain in `/etc/hosts` or use `curl --resolve`:

```bash
INGRESS_IP=$(kubectl get ingress campus-ingress-tls -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test Host 1: Portal with HTTPS (-k ignores self-signed certificate warning)
curl -k --resolve portal.campus.local:443:$INGRESS_IP https://portal.campus.local/

# Test Host 2: API with HTTPS
curl -k --resolve api.campus.local:443:$INGRESS_IP https://api.campus.local/api/health
```

#### 💡 Command Breakdown (cmd-explained):
* `INGRESS_IP=$(kubectl ...)`: Queries the live Ingress status and stores the controller's external IP address in an environment variable.
* `curl -k`: Flag `--insecure` (`-k`) allows curl to proceed with the TLS handshake even though our self-signed certificate is not signed by a recognized Certificate Authority (CA).
* `--resolve <host>:<port>:<ip>`: Overrides the operating system DNS lookup. Instructs curl that when contacting `portal.campus.local` on port `443`, send packets directly to `$INGRESS_IP` while retaining the SNI and Host header. Bypasses the need to modify `/etc/hosts` or local DNS servers!

### Cleanup
```bash
kubectl delete ingress campus-ingress-tls
kubectl delete secret campus-tls-cert
rm -f tls.key tls.crt
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl delete ingress/secret`: Removes the routing rules from the cluster and drops the SSL certificates.
* `rm -f tls.key tls.crt`: Deletes the temporary local self-signed key files from the host filesystem.

---

### 📚 Tech Jargons Demystified:
* **Ingress Resource vs Ingress Controller:**
  * **Ingress Resource:** A YAML declaration of routing rules (hosts, paths, services). It is passive and does nothing alone.
  * **Ingress Controller:** The active proxy software (NGINX, Traefik, HAProxy, Envoy) that evaluates Ingress resources and actually forwards client traffic.
* **IngressClass:** A cluster-level object specifying which Ingress Controller should implement a given Ingress resource (`spec.ingressClassName: nginx`).
* **PathType:**
  * `Exact`: Matches the URL path exactly, case-sensitively.
  * `Prefix`: Matches URL path prefixes segmented by `/` (e.g. `/api` matches `/api`, `/api/v1`).
  * `ImplementationSpecific`: Relies on controller-specific regular expressions.
* **TLS Termination (SSL Offloading):** The practice of terminating HTTPS connections at the Ingress boundary, decrypting the traffic, and forwarding raw HTTP packets to internal cluster pods to reduce cryptographic overhead on application containers.


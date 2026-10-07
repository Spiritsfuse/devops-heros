# Task 3: Kubernetes Fully Qualified Domain Name (FQDN)

## Student Information
- **Name:** Dhruv Sharma
- **Enrollment Number:** 24BCS10294

---

## 1. What is an FQDN?
**FQDN** stands for **Fully Qualified Domain Name**. It is the unambiguous, complete domain address that specifies the exact location of a host or service within the Domain Name System (DNS) hierarchy tree.

In contrast to a relative or short hostname (like `backend`), an FQDN leaves no ambiguity regarding which domain or namespace the entity belongs to.

---

## 2. Kubernetes Service DNS Architecture
In Kubernetes, every Service created is automatically registered into the cluster's internal DNS service (managed by **CoreDNS**). 

The cluster DNS assigns every Service a DNS record pointing to its stable virtual cluster IP (ClusterIP).

### Kubernetes DNS Naming Convention
A standard Kubernetes Service FQDN follows this exact hierarchical structure:

$$\text{<service-name>}.\text{<namespace>}.\text{svc}.\text{<cluster-domain>}$$

```text
  payment-service .  production  .   svc   .  cluster.local
  └──────┬──────┘   └─────┬────┘    └──┬──┘  └──────┬──────┘
         │                │            │            │
    Service Name      Namespace     Object Type   Cluster Domain
```

- **`<service-name>`**: The `metadata.name` defined in the Service manifest.
- **`<namespace>`**: The Kubernetes namespace where the service lives (`default`, `dev`, `prod`).
- **`svc`**: Identifies that this DNS record is for a Kubernetes **Service** (as opposed to `pod`).
- **`<cluster-domain>`**: The cluster root domain suffix, which defaults to `cluster.local`.

---

## 3. Namespace-Based DNS Resolution

When Pods make network requests, they can use different levels of qualification depending on where the destination Service resides:

| Source Pod Location | Destination Service Location | Minimal Valid Name | Full FQDN |
| :--- | :--- | :--- | :--- |
| `default` namespace | `default` namespace | `backend` | `backend.default.svc.cluster.local` |
| `frontend` namespace | `backend` namespace | `backend.backend` | `backend.backend.svc.cluster.local` |
| Any namespace / External | `production` namespace | `backend.production.svc.cluster.local` | `backend.production.svc.cluster.local` |

---

## 4. Pod-to-Service Communication Flow
Inside every container in a Pod, Kubernetes automatically injects the DNS configuration into `/etc/resolv.conf`:

```text
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

When a container in the `default` namespace calls `curl http://backend`:
1. The resolver queries CoreDNS for `backend.default.svc.cluster.local` using the first entry in the `search` domain list.
2. CoreDNS matches the record, finds the Service ClusterIP (e.g., `10.96.120.45`), and returns it to the client.
3. The client connects to the ClusterIP, where `kube-proxy` load-balances the TCP connection across healthy backend Pod endpoints.

---

## 5. Concrete Examples of Kubernetes FQDNs

1. **Standard ClusterIP Service**:
   - `cart-service.ecommerce.svc.cluster.local`
2. **Headless Service**:
   - Resolves directly to the set of individual Pod IPs rather than a single ClusterIP VIP:
   - `database-headless.database-tier.svc.cluster.local`
3. **StatefulSet Specific Pod FQDN**:
   - `postgres-0.database-headless.database-tier.svc.cluster.local`
   - `postgres-1.database-headless.database-tier.svc.cluster.local`
4. **ExternalName Service**:
   - CNAME redirect to external domain:
   - `my-db.default.svc.cluster.local -> db.external-provider.com`

---

## 6. Hands-On Verification & FQDN Testing Commands

To test and prove FQDN resolution inside your Kubernetes cluster, run an interactive testing container:

```bash
# Launch an interactive ephemeral container
kubectl run fqdn-tester --image=curlimages/curl:8.5.0 -it --rm -- sh

# Inside the test pod:
# 1. Test short service name resolution within the same namespace
curl -s http://payment-service:8080/health

# 2. Test cross-namespace communication using two-part qualification (<service>.<namespace>)
curl -s http://inventory-service.warehouse:8080/health

# 3. Test absolute FQDN resolution (bypassing search paths)
curl -s http://inventory-service.warehouse.svc.cluster.local:8080/health
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl run fqdn-tester --image=curlimages/curl:8.5.0 -it --rm -- sh`:
  * `run fqdn-tester`: Creates a lightweight pod named `fqdn-tester`.
  * `--image=curlimages/curl:8.5.0`: Uses an Alpine-based curl image.
  * `-it`: Interactive mode with TTY attached.
  * `--rm`: Ensures the test pod is automatically purged upon exit, keeping the cluster clean.
  * `sh`: Starts a POSIX shell session inside the container.
* `curl -s http://payment-service:8080/health`:
  * Resolves short name via pod's `/etc/resolv.conf` search path (`<service>.<namespace>.svc.cluster.local`).
  * `-s`: Silent flag suppressing curl's download progress.
* `curl -s http://inventory-service.warehouse:8080/health`:
  * Reaches across namespaces. Resolves through the second search entry: `warehouse.svc.cluster.local`.
* `curl -s http://inventory-service.warehouse.svc.cluster.local:8080/health`:
  * Sends the full canonical FQDN. CoreDNS resolves it immediately without iterating through search domains, saving DNS round trips.

---

### 📚 Tech Jargons Demystified:
* **FQDN (Fully Qualified Domain Name):** An absolute domain name ending with the root dot (explicit or implied), specifying the complete path from the host to the top-level domain (`service.namespace.svc.cluster.local`).
* **Search Domains:** Suffixes defined in `/etc/resolv.conf` that the OS automatically appends to unqualified domain names before querying the DNS server.
* **Relative / Unqualified Domain Name:** A simple name like `backend` or `database` that requires search path expansion to locate.
* **SRV (Service) Records:** Kubernetes DNS also creates SRV records for named ports (e.g. `_http._tcp.my-service.my-ns.svc.cluster.local`), enabling clients to discover both the port number and IP address dynamically.

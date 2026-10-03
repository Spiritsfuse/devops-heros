# Task 4: CoreDNS in Kubernetes

## Student Information
- **Name:** Dhruv Sharma
- **Enrollment Number:** 24BCS10294

---

## 1. What is CoreDNS?
**CoreDNS** is a flexible, extensible, and high-performance DNS server written in Go. It is an official Cloud Native Computing Foundation (CNCF) graduated project and serves as the default cluster DNS server in Kubernetes (replacing the legacy `kube-dns` since Kubernetes v1.13).

In Kubernetes, CoreDNS is deployed as a **Deployment** (typically 2 replicas for high availability) inside the `kube-system` namespace, exposed via a `kube-dns` Service with a fixed ClusterIP (usually `.10` of the service CIDR, e.g., `10.96.0.10`).

---

## 2. Why Kubernetes Uses CoreDNS
1. **Dynamic Service Discovery**: As Pods are scheduled, scaled up, killed, and replaced, their IP addresses change constantly. CoreDNS continuously tracks changes to Services and Endpoints via the Kubernetes API server.
2. **Pluggable Architecture**: CoreDNS uses a modular chained-plugin architecture (`kubernetes`, `forward`, `cache`, `errors`, `health`, `prometheus`), making it extremely lightweight and configurable.
3. **Low Memory Footprint**: CoreDNS is single-binary and highly efficient compared to legacy multi-container DNS solutions.
4. **Resilience & Observability**: Exposes native Prometheus metrics for query latency, error counts, and cache hit ratios.

---

## 3. How Service Discovery & DNS Resolution Work

```mermaid
sequenceDiagram
    autonumber
    actor App as Client Pod (frontend)
    participant Res as /etc/resolv.conf
    participant DNS as CoreDNS (10.96.0.10)
    participant API as kube-apiserver
    participant Svc as Backend Service (ClusterIP)

    Note over DNS,API: CoreDNS continuously watches Services & Endpoints
    App->>Res: Query "backend"
    Res->>DNS: Resolves using search domain "backend.default.svc.cluster.local"
    DNS->>App: Returns Service ClusterIP (e.g. 10.96.150.30)
    App->>Svc: Sends HTTP traffic directly to ClusterIP
```

1. **Watch Loop**: The `kubernetes` plugin in CoreDNS watches the Kubernetes API server for additions, updates, or deletions of `Service` and `EndpointSlice` resources.
2. **Client Query**: A Pod sends an A/AAAA record DNS lookup request to the nameserver IP configured in its `/etc/resolv.conf`.
3. **Internal Lookup**: If the query matches the cluster domain (`cluster.local`), CoreDNS resolves the record internally using its in-memory table.
4. **Upstream Forwarding**: If the query is external (e.g., `google.com` or `github.com`), the `forward` plugin sends the query to the node's upstream DNS server (e.g., `8.8.8.8` or corporate DNS).
5. **Caching**: Responses are cached locally according to TTL settings to minimize lookup latency.

---

## 4. CoreDNS Configuration (`Corefile`)
CoreDNS configuration is managed declaratively via a Kubernetes ConfigMap named `coredns` in the `kube-system` namespace:

```text
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
```

### Key Plugins Explained:
- **`errors`**: Logs errors to standard output.
- **`health`**: Serves health checks on port 8080 (`/health`).
- **`kubernetes`**: Resolves DNS queries based on the Kubernetes API resources for the `cluster.local` domain.
- **`forward . /etc/resolv.conf`**: Forwards any non-cluster queries to host node resolvers.
- **`cache 30`**: Caches DNS responses for up to 30 seconds.
- **`loadbalance`**: Acts as a round-robin DNS load balancer across multiple IP records.

---

## 5. How to Troubleshoot DNS Issues

When a Pod cannot reach a Service by name, follow this systematic troubleshooting checklist:

```bash
# 1. Verify CoreDNS Pods are running
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 2. Check CoreDNS logs for failures or loop crashes
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

# 3. Check the kube-dns Service and endpoints
kubectl get svc,endpoints -n kube-system -l k8s-app=kube-dns

# 4. Run an interactive DNS diagnostic Pod (dnsutils / netshoot)
kubectl run dns-test --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 -it --rm -- bash

# Inside the test container:
# Test cluster-internal resolution
nslookup kubernetes.default
nslookup payment-service.default.svc.cluster.local

# Test external resolution
nslookup google.com

# Inspect local resolver settings
cat /etc/resolv.conf
```

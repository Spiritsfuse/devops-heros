# Canary Deployment Strategy

## What is a Canary Deployment?

A **Canary Deployment** is a risk-reduction strategy where you release a new version of your application to a **small percentage of real users first**, while the rest continue on the old stable version. You monitor the canary for errors, latency, or abnormal behavior before gradually shifting more traffic to it.

The name comes from mining history: coal miners used to carry canary birds into mines. If the canary died, it warned the miners of toxic gas before the gas could harm them. Similarly, the canary pods absorb any defects in a new release before all users are impacted.

```text
                     [SERVICE] (port 30030)
                          |
          [kube-proxy distributes requests across ALL pods]
                          |
     +--------------------+------------------------+
     |         |         |         |         |     |
     v         v         v         v         v     v
[stable] [stable] [stable] [stable] [stable] ... [canary]
  v1       v1       v1       v1       v1     (x9)  v2 (x1)
90% of requests land on stable v1        10% land on canary v2
```

---

## Why Do We Need Canary?

### Problems with Rolling Update and Blue-Green:
* **Rolling Update:** You cannot control what percentage of users see the new version during the update. All users are exposed as soon as the first new pod starts.
* **Blue-Green:** The switch is all-or-nothing (100% flip). If v2 has a subtle bug that only appears under high traffic conditions, you discover it after all users are on v2.

### Benefits of Canary:
* Only 10% of real users are exposed to risk while you validate v2 in production conditions.
* You can observe real production metrics (error rate, response time, CPU usage) for v2 before promoting it to 100%.
* If the canary shows problems, you simply scale it to 0 replicas. 90% of users never experienced the bug.

---

## How Traffic Split Works in Kubernetes (Pod Ratio Math)

Kubernetes Services use **round-robin** load balancing across all matching pod endpoints. There are no traffic-weight configurations. Traffic split is purely driven by **pod count ratio**:

| Stable Replicas | Canary Replicas | Total Pods | Canary Traffic % |
| :--- | :--- | :--- | :--- |
| 9 | 1 | 10 | 10% |
| 8 | 2 | 10 | 20% |
| 5 | 5 | 10 | 50% |
| 2 | 8 | 10 | 80% |
| 0 | 10 | 10 | 100% (fully promoted) |

---

## Important Points

* **The Service selects BOTH stable and canary pods** using only the shared label (`app: myapp-canary`). The `track: stable` and `track: canary` labels are for human identification only — not for routing.
* Kubernetes-native canary is **approximate** (uses pod-ratio math). For precise percentage control (e.g. exactly 5.3%), use **Argo Rollouts**, **Flagger**, or an Ingress-level traffic split (e.g. NGINX Ingress weight annotations).
* Monitor the canary for at least **1 full traffic cycle** (15-30 minutes in production) before increasing traffic.
* Always define alerting thresholds BEFORE the canary goes live: "If error rate > 1% on canary pods for 5 minutes, auto-rollback."

---

## Production Use Cases

* Google, Netflix, and Meta use canary deployments for every single code push to production.
* Feature flags are often combined with canary: send 10% of traffic to new pods AND enable the new feature flag only for those 10%.
* Machine learning model updates: serve the new model to 5% of users, compare prediction accuracy vs the old model, then promote.

---

## Code Files

| File | Purpose |
| :--- | :--- |
| `deployment-stable.yaml` | 9 replicas of v1 (stable, dark background) — 90% traffic |
| `deployment-canary.yaml` | 1 replica of v2 (canary, orange background) — 10% traffic |
| `service.yaml` | NodePort Service on `30030`, selecting both stable and canary pods |

---

## Step-by-Step Commands

### Step 1: Deploy Stable v1 (9 Pods = 90% Traffic)
```bash
kubectl apply -f 03-canary/deployment-stable.yaml
```

#### 💡 Command Breakdown (`cmd-explained`):
- `apply -f`: Creates the baseline production deployment running 9 replicas of stable v1 code.
- Label: `app=myapp-canary,track=stable,version=v1`.

Wait until all 9 stable pods are running:
```bash
kubectl rollout status deployment/app-stable
```

#### 💡 Command Breakdown (`cmd-explained`):
- `rollout status`: Blocks until all 9 pods pass their readiness checks, ensuring baseline stability before routing any traffic.

### Step 2: Deploy the Service
```bash
kubectl apply -f 03-canary/service.yaml
```

#### 💡 Command Breakdown (`cmd-explained`):
- Notice that the Service selector is intentionally configured as `app: myapp-canary`.
- It does **not** specify `track` or `version`. Therefore, any pod carrying `app=myapp-canary` will be added to the service endpoint pool!

### Step 3: Test — All Traffic Goes to Stable v1
```bash
for i in $(seq 1 10); do curl -s http://$(minikube ip):30030 | grep -o "STABLE v1\|CANARY v2"; done
```

#### 💡 Command Breakdown (`cmd-explained`):
- `for i in $(seq 1 10); do ... done`: Bash for-loop iterating 10 times.
- `curl -s`: Silent HTTP GET request against the NodePort service.
- `grep -o "STABLE v1\|CANARY v2"`: Extracts and outputs only the matching version string pattern using regex alternation (`\|`).
- Proves 100% of the traffic lands on stable v1 because no canary pods exist yet.

Expected output (10 out of 10 requests hit stable):
```text
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
```

### Step 4: Deploy the Canary v2 Pod (1 Pod = 10% Traffic)
```bash
kubectl apply -f 03-canary/deployment-canary.yaml
```

#### 💡 Command Breakdown (`cmd-explained`):
- Spawns exactly 1 replica running the new v2 candidate image with labels `app=myapp-canary,track=canary,version=v2`.
- Because this pod has `app=myapp-canary`, Kubernetes automatically adds its IP to the Service's 10-endpoint pool, achieving an automatic **90/10 traffic split** via round-robin kube-proxy load balancing!

Wait until the canary pod is running:
```bash
kubectl get pods -l app=myapp-canary --show-labels
```

#### 💡 Command Breakdown (`cmd-explained`):
- Displays all 10 pods, clearly delineating the 9 stable pods from the 1 canary pod by label.

Expected output (9 stable + 1 canary = 10 pods total):
```text
NAME                           READY   STATUS    LABELS
app-stable-6d7f8c5b4-2mqpt    1/1     Running   app=myapp-canary,track=stable,version=v1
app-stable-6d7f8c5b4-4krgn    1/1     Running   app=myapp-canary,track=stable,version=v1
app-stable-6d7f8c5b4-7jxqz    1/1     Running   app=myapp-canary,track=stable,version=v1
...  (9 stable total)
app-canary-9b6d4e7c8-5fmpx    1/1     Running   app=myapp-canary,track=canary,version=v2
```

### Step 5: Verify Traffic Split in Real Time
```bash
for i in $(seq 1 20); do curl -s http://$(minikube ip):30030 | grep -o "STABLE v1\|CANARY v2"; done
```

#### 💡 Command Breakdown (`cmd-explained`):
- Sends 20 requests in sequence.
- Statistically, with 10 total pods in the endpoint list, approximately 10% (1 in 10, or 2 in 20) route to the canary pod.

Expected output (approximately 1-2 canary hits out of 20):
```text
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
CANARY v2   <- approximately 1 in 10 requests hits the canary
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
```

### Step 6: Increase Canary Traffic to 30% (3 out of 10 Pods)
```bash
kubectl scale deployment app-canary --replicas=3
kubectl scale deployment app-stable --replicas=7
```

#### 💡 Command Breakdown (`cmd-explained`):
- `scale deployment ... --replicas=<num>`: Adjusts pod counts to shift the traffic weighting from 90/10 to 70/30.
- 3 canary pods + 7 stable pods = 30% canary traffic.

Verify endpoints updated:
```bash
kubectl get endpoints myapp-canary-service
# Now shows 10 endpoints: 7 stable IPs + 3 canary IPs
```

Re-run the traffic test:
```bash
for i in $(seq 1 10); do curl -s http://$(minikube ip):30030 | grep -o "STABLE v1\|CANARY v2"; done
# Expect approximately 3 CANARY v2 in 10 requests
```

### Step 7A: Promote Canary to 100% (Canary is Healthy)
```bash
# Scale canary to full replicas and remove stable
kubectl scale deployment app-canary --replicas=9
kubectl scale deployment app-stable --replicas=0
```

#### 💡 Command Breakdown (`cmd-explained`):
- When metric error rates on canary are verified clean, scale the canary deployment up to full capacity (`--replicas=9`) and scale stable down to 0.

All 10 requests now hit v2:
```bash
for i in $(seq 1 5); do curl -s http://$(minikube ip):30030 | grep -o "STABLE v1\|CANARY v2"; done
# CANARY v2 x5
```

After confirming stable, clean up old stable deployment:
```bash
kubectl delete deployment app-stable
```

### Step 7B: Rollback Canary (Canary is Broken)
```bash
kubectl scale deployment app-canary --replicas=0
kubectl scale deployment app-stable --replicas=9
```

#### 💡 Command Breakdown (`cmd-explained`):
- If the canary throws 500 errors or high latency in APM/Prometheus, immediately zero out the canary replicas (`--replicas=0`) and scale stable back to 9. The blast radius was restricted to only a tiny fraction of user requests.

All traffic instantly returns to v1 stable:
```bash
for i in $(seq 1 5); do curl -s http://$(minikube ip):30030 | grep -o "STABLE v1\|CANARY v2"; done
# STABLE v1 x5
```

---

## Cleanup
```bash
kubectl delete -f 03-canary/service.yaml
kubectl delete -f 03-canary/deployment-canary.yaml
kubectl delete -f 03-canary/deployment-stable.yaml
```

#### 💡 Command Breakdown (`cmd-explained`):
- Tears down the service and both stable and canary deployments, returning the cluster to a clean slate.

---

### 📚 Tech Jargons Demystified:
- **Canary Release**: Named after coal miners using canaries to detect toxic gas; deploying a new release to a small subset of live users to detect bugs early before full rollout.
- **Blast Radius**: The maximum extent of damage or user disruption caused if a failure occurs (canary minimizes blast radius to ~5-10% of users).
- **Traffic Weighting**: Distributing incoming requests across multiple backend versions according to specific ratios (e.g. 90% stable, 10% canary). In pure Kubernetes, this is achieved by the ratio of pod replicas; in service meshes (like Istio/Linkerd), it can be achieved by HTTP header/percentage rules.
- **Promotion vs Abort**:
  - *Promotion*: Scaling the canary to 100% and decommissioning the old release.
  - *Abort*: Immediately scaling the canary to 0 replicas to protect users.

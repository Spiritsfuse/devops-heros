# Kubernetes HPA


**HPA** means:
> **Horizontal Pod Autoscaler**

---

## 1. Why Do We Need HPA?

Imagine our application has:

* `1 Pod`

During normal traffic:

* `CPU = 20%`

But suddenly many users start using the application:

* `CPU = 90%`

We may need more Pods.

Instead of manually running:

```bash
kubectl scale deployment hpa-demo --replicas=5
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl scale deployment <name> --replicas=5`: Imperative scaling command. Instructs the Deployment controller to immediately change the desired replica count to 5 without modifying YAML files. Manual scaling lacks dynamism and cannot react automatically to traffic spikes.

HPA can automatically change the number of replicas.

---

## 2. Horizontal Scaling

Horizontal scaling means:

> **Add more Pods**

### Example:

```text
Before:
  Pod 1

After scaling:
  Pod 1   Pod 2   Pod 3   Pod 4
```

HPA does **not** make the existing Pod bigger.

---

## 3. Deployment

Create the Deployment:

```bash
kubectl apply -f deployment.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f deployment.yaml`: Creates the workload. Critical: the Pod template MUST define `resources.requests.cpu`, otherwise HPA cannot compute percentage utilization and will report `<unknown>`.

Check:

```bash
kubectl get deployment
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get deployment`: Verifies the deployment state, checking `UP-TO-DATE` and `AVAILABLE` replica counts.

Then:

```bash
kubectl get pods
```

---

## 4. CPU Requests

Our Deployment contains:

```yaml
resources:
  requests:
    cpu: 100m
```

CPU requests are important for CPU utilization calculations used by HPA.

For example:

* CPU request = `100m`
* CPU usage   = `50m`
* Utilization = `50%`

---

## 5. Service

Create the Service:

```bash
kubectl apply -f service.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f service.yaml`: Exposes the pods internally via a ClusterIP service so traffic from the load generator can be distributed across all available pod replicas.

Check:

```bash
kubectl get svc
```

Expected output:

```text
NAME               TYPE        CLUSTER-IP
hpa-demo-service   ClusterIP   ...
```

---

## 6. Metrics Server

HPA needs metrics.

Check:

```bash
kubectl top nodes
```

and:

```bash
kubectl top pods
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl top nodes`: Displays current CPU and memory consumption across worker nodes by querying the Kubernetes Metrics Server API (`metrics.k8s.io`).
* `kubectl top pods`: Displays real-time CPU (in millicores, `m`) and memory (in megabytes, `Mi`) consumed by each active container.

If you get:

```text
Metrics API not available
```

Metrics Server is not available yet.

For Minikube:

```bash
minikube addons enable metrics-server
```

#### 💡 Command Breakdown (cmd-explained):
* `minikube addons enable metrics-server`: Deploys the cluster metric aggregator pod in `kube-system`, collecting resource usage metrics from each node's kubelet cAdvisor.

Check:

```bash
kubectl get pods -n kube-system
```

Look for:

```text
metrics-server-xxxxx
```

Then try again:

```bash
kubectl top pods
```

---

## 7. Create HPA

Apply:

```bash
kubectl apply -f hpa.yaml
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl apply -f hpa.yaml`: Deploys the HorizontalPodAutoscaler object. The HPA controller begins periodic polling (default every 15 seconds) against the Metrics Server API.

Check:

```bash
kubectl get hpa
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get hpa`: Displays current metrics targets vs thresholds (`TARGETS: 0%/50%`), min/max bounds, and current replica count.

You may see:

```text
NAME       TARGETS   MINPODS   MAXPODS   REPLICAS
hpa-demo   0%/50%    1         5         1
```

The exact CPU percentage will depend on your system.

---

## 8. Generate Load

Run the load generator:

```bash
kubectl run load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c \
  "while true; do wget -q -O- http://hpa-demo-service; done"
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl run load-generator`: Spawns a dedicated traffic generator pod.
* `--image=busybox:1.36`: Uses lightweight BusyBox image containing the `wget` utility.
* `--restart=Never`: Configures this as a standalone Pod rather than a Deployment or Job.
* `-- /bin/sh -c "while true; do wget -q -O- http://hpa-demo-service; done"`: Runs an infinite shell loop hammering the service endpoint with HTTP requests, driving CPU consumption above the 50% target threshold.

Watch HPA:

```bash
kubectl get hpa -w
```

#### 💡 Command Breakdown (cmd-explained):
* `-w` (`--watch`): Keeps the terminal output streaming live updates whenever HPA recalculates replica requirements: $\lceil \text{currentReplicas} \times (\text{currentMetricValue} / \text{desiredMetricValue}) \rceil$.

Also watch Pods:

```bash
kubectl get pods -w
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl get pods -w`: Streams pod creation events live, showing replicas scaling from 1 to 2, 3, 4, up to the defined `maxReplicas` of 5.

When CPU increases, HPA can increase the number of Pods.

---

## 9. Stop The Load

Delete the load generator:

```bash
kubectl delete pod load-generator
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl delete pod load-generator`: Terminates the infinite traffic loop. CPU utilization drops back down toward 0%.

Watch:

```bash
kubectl get hpa -w
```

After some time, the number of replicas can decrease again.

---

## 10. HPA Flow

Remember this:

```text
Application
     │
     ▼
 CPU usage
     │
     ▼
Metrics Server
     │
     ▼
    HPA
     │
     ▼
 Deployment
     │
     ▼
More / fewer Pods
```

---

## 11. Important HPA Fields

* **`scaleTargetRef`**: Which workload should HPA scale?
* **`minReplicas`**: Minimum number of Pods.
* **`maxReplicas`**: Maximum number of Pods.
* **`metrics`**: What should HPA monitor?

---

## Useful Commands

```bash
kubectl top nodes
kubectl top pods
kubectl get hpa
kubectl describe hpa hpa-demo
kubectl get deployment
kubectl get pods
kubectl get pods -w
```

#### 💡 Command Breakdown (cmd-explained):
* `kubectl describe hpa hpa-demo`: Displays the complete scaling event log, showing reasons for scale-up actions and scale-down stabilization delay timers (`SuccessfulRescale`).

---

## Key Learning

Remember:

* **HPA** = Automatically changes Pod count
* **High load** = More Pods
* **Low load** = Fewer Pods

---

## Reference

* **Horizontal Pod Autoscaling:**  
  https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/
* **HPA Walkthrough:**  
  https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
* **Metrics Pipeline:**  
  https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/

---

### 📚 Tech Jargons Demystified:
* **Horizontal Pod Autoscaler (HPA):** A Kubernetes control loop that automatically scales the number of Pod replicas in a Deployment or ReplicaSet based on observed CPU/Memory utilization or custom metrics.
* **Metrics Server:** An in-memory, lightweight cluster add-on that collects resource metrics (`cAdvisor`) from kubelets and exposes them via the `metrics.k8s.io` API for HPA and `kubectl top`.
* **CPU Millicores (`m`):** 1 vCPU / physical core = $1000\text{m}$. A request of $100\text{m}$ equals 10% of one CPU core.
* **Scale-Down Stabilization Window:** A cooldown period (default 5 minutes / 300 seconds) preventing "flapping" or "thrashing" (rapid bouncing between scaling up and scaling down when traffic fluctuates).
* **Vertical vs Horizontal Pod Autoscaler:**
  * **HPA (Horizontal):** Changes the *number* of pods (adds more instances).
  * **VPA (Vertical):** Changes the *size* of individual pods (allocates more CPU/memory to existing containers).

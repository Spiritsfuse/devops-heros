# 03 - Kubernetes Deployment

## Objective

Deploy the Docker image stored in GHCR to Kubernetes.

## Kubernetes Manifests

```text
k8s/
├── deployment.yaml
└── service.yaml
```

## deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devsecops-python
spec:
  replicas: 2
  selector:
    matchLabels:
      app: devsecops-python
  template:
    metadata:
      labels:
        app: devsecops-python
    spec:
      containers:
        - name: devsecops-python
          image: ghcr.io/OWNER/REPOSITORY:TAG
          ports:
            - containerPort: 5000
          readinessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 10
            periodSeconds: 20
```

Replace the image with the exact image pushed to GHCR.

## service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: devsecops-python-service
spec:
  type: NodePort
  selector:
    app: devsecops-python
  ports:
    - port: 5000
      targetPort: 5000
      nodePort: 30080
```

## Manual Deployment

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

#### 💡 Command Breakdown (cmd-explained):
- `kubectl apply -f <file>`: Declaratively creates or updates Kubernetes API resources defined in YAML manifests.
- `-f` (or `--filename`): Points to the target file or directory of resource specifications.

Check:

```bash
kubectl get deployment
kubectl get pods
kubectl get service
```

Test a local cluster:

```bash
kubectl port-forward svc/devsecops-python-service 8080:5000
curl http://localhost:8080/health
```

#### 💡 Command Breakdown (cmd-explained):
- `kubectl port-forward svc/<name> 8080:5000`: Establishes a direct local TCP proxy from localhost port 8080 to the Kubernetes Service's target port 5000, allowing local testing without cloud load balancers.
- `curl http://localhost:8080/health`: Sends an HTTP GET request to verify the Flask/FastAPI health endpoint responds with `200 OK`.

---

## Deployment from GitHub Actions

A GitHub-hosted runner needs Kubernetes credentials and network access to the target cluster.

```yaml
deploy:
  name: Deploy to Kubernetes
  needs:
    - push
  runs-on: ubuntu-latest
  environment:
    name: development

  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup kubectl
      uses: azure/setup-kubectl@v4
      with:
        version: latest

    - name: Configure Kubernetes
      run: |
        mkdir -p ~/.kube
        echo "${{ secrets.KUBE_CONFIG }}" | base64 --decode > ~/.kube/config

    - name: Update application image
      run: |
        kubectl set image deployment/devsecops-python \
          devsecops-python=ghcr.io/${{ github.repository }}:${{ github.sha }}

    - name: Wait for rollout
      run: |
        kubectl rollout status deployment/devsecops-python

    - name: Verify deployment
      run: |
        kubectl get deployment devsecops-python
        kubectl get pods
```

#### 💡 Command Breakdown (cmd-explained):
- `azure/setup-kubectl@v4`: Installs and configures the `kubectl` CLI tool directly on the GitHub runner.
- `base64 --decode > ~/.kube/config`: Decodes the base64-encoded Kubernetes cluster connection credentials stored in GitHub Secrets and writes it to the default `~/.kube/config` location.
- `kubectl set image deployment/devsecops-python devsecops-python=<image>`: Imperatively mutates the pod template's image definition inside the Deployment object, triggering a Kubernetes rolling update.
- `kubectl rollout status deployment/devsecops-python`: Synchronously monitors the rolling update in real-time, blocking the pipeline until all newly scheduled pods pass readiness probes or timing out on failure.

`kubectl set image` updates the Deployment's container image and triggers a rolling update. `kubectl rollout status` watches the rollout until it completes.

## Important Classroom Note

A GitHub-hosted runner cannot automatically reach Kubernetes running on a student's laptop through Docker Desktop, Kind, or Minikube.

For the classroom:

```text
GitHub Actions
   ↓
Build + Security + GHCR

Local Kubernetes
   ↓
Manual deployment practice
```

For real automated CD, use a reachable cloud/shared cluster or an appropriately configured self-hosted runner.

---

### 📚 Tech Jargons Demystified:
- **Rolling Update:** An automated deployment strategy where old pods are incrementally terminated only as new pods pass readiness probes, ensuring zero application downtime.
- **`kubectl rollout status`:** A blocking command monitoring the transition state of a deployment until all replicas are up to date and healthy.
- **Kubeconfig Secret:** A base64-encoded `~/.kube/config` file injected into CI/CD runners containing API server endpoints, TLS certificates, and service account tokens to authenticate against remote Kubernetes clusters.
- **Readiness vs Liveness Probes:** Readiness probes tell Kubernetes when a pod is ready to accept user network traffic; liveness probes tell Kubernetes when to restart an unhealthy container.

---

## Practice Questions

1. Push the image to GHCR.
2. Deploy it to local Kubernetes.
3. Change the image tag.
4. Run `kubectl set image`.
5. Watch the rollout.
6. Verify the new Pods.

# Session 14 Screenshots

This directory stores verified execution screenshots for Kubernetes troubleshooting:
- `01-kubectl-apply-and-get-wide.png`: Application of `sample-workload.yaml`, `kubectl get pods`, and `kubectl get pods -o wide` displaying Pod IP and node placement.
- `02-kubectl-delete-pod.png`: Terminal command deleting the `get-demo` pod gracefully.
- `03-kubectl-watch-pod-termination.png`: Observation of pod lifecycle transition (`Terminating` to `Completed`) using `kubectl get pods -w` and verification with `kubectl get all`.

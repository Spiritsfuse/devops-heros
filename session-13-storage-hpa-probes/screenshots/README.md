# Session 13 Screenshots

This directory stores verified execution screenshots for Kubernetes Storage, HPA, and Probes:
- `01-hpa-initial-status.png`: Deployment, Service, and HPA applied, verifying initial 1 replica and 0%/50% CPU target.
- `02-load-generator-launch.png`: Command launch running the BusyBox synthetic load generator.
- `02-load-generator-traffic-stream.png`: Real-time HTTP GET traffic stream against the Nginx service.
- `03-hpa-cpu-utilization-scaling.png`: Watching HPA CPU utilization adjustments in real-time (`kubectl get hpa -w`).

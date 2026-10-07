# 07 - Container Image Scanning

Scan the final Docker image for known vulnerabilities before publishing or deploying it.

## Why Scan the Image?

Source code can be clean while the final image still contains vulnerable:

- OS packages
- Python packages
- System libraries
- Other installed components

Therefore, scan the container image itself.

## Tool: Trivy

Build the image:

```bash
docker build -t session17-python:1.0 .
```

Scan:

```bash
trivy image session17-python:1.0
```

Scan HIGH and CRITICAL findings:

```bash
trivy image \
  --severity HIGH,CRITICAL \
  session17-python:1.0
```

## Make the Scan a Gate

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  session17-python:1.0
```

#### 💡 Command Breakdown (cmd-explained):
- `trivy image`: Invokes Aqua Security's Trivy vulnerability scanner against the local or remote container image layers, base OS filesystem packages (e.g. Alpine, Debian, Ubuntu), and language dependencies.
- `--severity HIGH,CRITICAL`: Filters scan analysis to only report vulnerabilities classified as `HIGH` or `CRITICAL` according to CVSS (Common Vulnerability Scoring System), ignoring low/medium alerts.
- `--exit-code 1`: **Crucial CI/CD flag!** By default, Trivy outputs vulnerability tables and exits with `0` (success). `--exit-code 1` forces Trivy to return non-zero exit code 1 if any matching vulnerabilities are detected, immediately breaking the pipeline and preventing vulnerable image deployment.

If the command exits with code `1`, the GitHub Actions step fails unless failure is explicitly allowed.

## Pipeline Flow

```text
Docker Build
     ↓
Trivy Scan
     ↓
Findings?
  /      \
FAIL     PASS
  ↓        ↓
STOP    Continue
```

## GitHub Actions Example

```yaml
- name: Scan image
  run: |
    trivy image \
      --severity HIGH,CRITICAL \
      --exit-code 1 \
      ghcr.io/${{ github.repository }}:${{ github.sha }}
```

## Important

HIGH/CRITICAL is a classroom example threshold, not a universal security policy. Organizations should define thresholds based on application risk and their security policy.

---

### 📚 Tech Jargons Demystified:
- **Container Image Scanning:** Analyzing all container image layers, including operating system binaries (e.g., `glibc`, `openssl`, `curl`) and language packages, against vulnerability databases.
- **Trivy:** An open-source, comprehensive vulnerability scanner for container images, Git repositories, Kubernetes manifests, and cloud configurations.
- **Security Gate:** An automated checkpoint in a CI/CD pipeline that blocks progression if security thresholds (e.g. zero critical CVEs) are violated.
- **CVSS (Common Vulnerability Scoring System):** A standardized 0–10 scoring framework quantifying vulnerability severity: Low (0.1–3.9), Medium (4.0–6.9), High (7.0–8.9), and Critical (9.0–10.0).

---

## Practice Questions

1. Build the image.
2. Run a normal Trivy scan.
3. Run a HIGH/CRITICAL scan.
4. Explain `--exit-code 1`.


# 02 - Container Registry

Store the Docker image in a container registry so Kubernetes or another environment can pull it.

For this session we use **GitHub Container Registry (GHCR)**.

## Flow

```text
Docker Build
     ↓
Docker Image
     ↓
GHCR
     ↓
Kubernetes
```

## Image Name

```text
ghcr.io/OWNER/REPOSITORY:TAG
```

Example:

```text
ghcr.io/my-user/session17-devsecops-python:8a72f31
```

## GitHub Actions Permissions

```yaml
permissions:
  contents: read
  packages: write
```

## Login to GHCR

```yaml
- name: Login to GHCR
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

## Build and Push

```yaml
- name: Build image
  run: |
    docker build \
      -t ghcr.io/${{ github.repository }}:${{ github.sha }} .

- name: Push image
  run: |
    docker push \
      ghcr.io/${{ github.repository }}:${{ github.sha }}
```

#### 💡 Command Breakdown (cmd-explained):
- `docker/login-action@v3`: Standard Docker action that logs the runner into `ghcr.io` securely using `${{ secrets.GITHUB_TOKEN }}`.
- `docker build`: Compiles the container image from the local `Dockerfile`.
- `-t ghcr.io/${{ github.repository }}:${{ github.sha }}`: Tags the image with the unique git commit SHA (`${{ github.sha }}`) to create an immutable version tag for full traceability.
- `docker push`: Uploads all layers of the built image to GitHub Container Registry.
- `permissions.packages: write`: Grants the workflow token write access to publish OCI container packages.

GitHub documents `GITHUB_TOKEN` authentication and `packages: write` permission for publishing repository-associated images to GHCR.

---

### 📚 Tech Jargons Demystified:
- **Container Registry:** A centralized cloud or on-prem storage service (like GHCR, Docker Hub, AWS ECR, or Google Artifact Registry) for storing, scanning, and distributing versioned container images.
- **Commit SHA Tagging (`${{ github.sha }}`):** Tagging container images with the exact 40-character Git commit hash instead of mutable tags like `:latest`, ensuring 100% reproducibility and preventing cache overwrites.
- **OCI (Open Container Initiative):** Industry standards governing container format and runtime specifications so images built by Docker can run interchangeably on Kubernetes (CRI-O, containerd).
- **Package Scope:** Access permissions determining whether a container image is public, internal to an organization, or strictly private.

---

## Verify

Open the GitHub repository and find the published container package. Confirm that its tag matches the commit SHA.

---

## Practice Questions

1. Build an image.
2. Login to GHCR through Actions.
3. Push the image.
4. Find the package in GitHub.
5. Copy the exact image name and tag.


# Artifacts

```yaml
- name: Upload test report
  uses: actions/upload-artifact@v4
  with:
    name: test-results
    path: test-output/
```

Artifacts let jobs share files and let you download outputs after a run.

---

## 1. What is an Artifact?

An artifact is any file or directory produced during a workflow run that you want to save.

```text
Examples:
  test-results.xml    = test report
  coverage.html       = code coverage report
  app.jar             = compiled application
  dist/               = built web app
  image.tar           = Docker image saved to disk
```

---

## 2. Why Artifacts?

Problem without artifacts:

```text
Build job compiles the app
Test job needs the compiled app
But Test runs on a different machine
Test cannot access Build's files
```

With artifacts:

```text
Build job compiles and uploads artifact
Test job downloads artifact and uses it
```

---

## 3. Upload an Artifact

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build application
        run: |
          mkdir dist
          echo "build output" > dist/app.txt

      - name: Upload build artifact
        uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: dist/
          retention-days: 7
```

`retention-days:` controls how long GitHub stores the artifact.

---

## 4. Download an Artifact in Another Job

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: mkdir dist && echo "built" > dist/app.txt
      - uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: dist/

  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Download build artifact
        uses: actions/download-artifact@v4
        with:
          name: build-output
          path: dist/

      - name: Run test against artifact
        run: cat dist/app.txt
```

---

## 5. Test Reports as Artifacts

```yaml
- name: Run tests with report
  run: pytest --junitxml=test-results/results.xml

- name: Upload test report
  uses: actions/upload-artifact@v4
  with:
    name: test-report
    path: test-results/
```

After the run, you can download the report from the GitHub Actions UI.

---

## 6. Docker Image as Artifact

Save a Docker image to disk and upload it:

```yaml
- name: Build Docker image
  run: docker build -t myapp:latest .

- name: Save Docker image
  run: docker save myapp:latest > myapp.tar

- name: Upload image artifact
  uses: actions/upload-artifact@v4
  with:
    name: docker-image
    path: myapp.tar
```

Download and load it in another job:

```yaml
- name: Download image artifact
  uses: actions/download-artifact@v4
  with:
    name: docker-image

- name: Load Docker image
  run: docker load < myapp.tar
```

#### 💡 Command Breakdown (cmd-explained):
- `docker build -t myapp:latest .`: Builds a Docker container image tagged `myapp:latest` using the `Dockerfile` in the current directory (`.`).
- `docker save myapp:latest > myapp.tar`: Exports the container image layers into a standalone compressed tar archive (`myapp.tar`) on disk so it can be uploaded as an artifact.
- `docker load < myapp.tar`: Re-imports the container image tarball back into the local Docker daemon engine on a different runner machine.
- `pytest --junitxml=test-results/results.xml`: Generates a standard JUnit XML formatted test execution report for test result dashboards.

---

## 7. Artifact Retention

```text
Default retention:    90 days
Minimum retention:    1 day
Maximum retention:    90 days (free accounts), 400 days (enterprise)
```

Set custom retention:

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: test-report
    path: results/
    retention-days: 14
```

---

## Key Learning

```text
Artifact           = file or directory saved from a workflow run
upload-artifact    = saves files from a job
download-artifact  = retrieves files in a later job
needs:             = required to download artifacts from a previous job
retention-days:    = how long GitHub stores the artifact
```

---

### 📚 Tech Jargons Demystified:
- **`actions/upload-artifact@v4`:** Action that compresses specified local paths into a zip archive and registers it under the current workflow run.
- **`actions/download-artifact@v4`:** Action that retrieves previously uploaded artifacts in downstream dependent jobs.
- **Artifact Ephemerality vs Retention:** Artifacts are retained for a configurable number of days (`retention-days:`) before being purged automatically to prevent runaway cloud storage consumption.
- **Docker Image Portability via Tar:** Exporting images via `docker save` enables sharing image builds across runners without publishing intermediate untested images to an external registry.

---

## Reference

* **Storing workflow data as artifacts:** https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/storing-and-sharing-data-from-a-workflow
* **actions/upload-artifact:** https://github.com/actions/upload-artifact
* **actions/download-artifact:** https://github.com/actions/download-artifact


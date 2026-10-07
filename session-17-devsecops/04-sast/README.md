# 04 - SAST

Scan source code for security weaknesses before deployment.

SAST means **Static Application Security Testing**.

## What Does SAST Check?

```text
Source Code
    ↓
SAST Tool
    ↓
Security Analysis
    ↓
Findings
```

It analyzes source code without requiring the application to be running.

## Tool: GitHub CodeQL

```yaml
sast:
  name: SAST - CodeQL
  runs-on: ubuntu-latest
  permissions:
    contents: read
    security-events: write

  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Initialize CodeQL
      uses: github/codeql-action/init@v3
      with:
        languages: python

    - name: Analyze code
      uses: github/codeql-action/analyze@v3
```

#### 💡 Command Breakdown (cmd-explained):
- `github/codeql-action/init@v3`: Initializes GitHub's CodeQL analysis engine and builds an abstract syntax database of your code for specified languages (e.g. `python`, `javascript`).
- `github/codeql-action/analyze@v3`: Runs deep static semantic and dataflow queries against the CodeQL database, uploads results as SARIF files to GitHub, and displays alerts under the Security tab.
- `permissions.security-events: write`: Mandatory permission allowing the workflow to upload SARIF security alerts into the repository's GitHub Advanced Security dashboard.

## Difference from Other Scans

| Scan | Checks |
|---|---|
| SAST | Source code |
| SCA | Dependencies |
| Secret scanning | Credentials/secrets |
| Image scanning | Container image |

## Classroom Practice

1. Add the CodeQL job.
2. Push the workflow.
3. Open the repository Security area.
4. Review code-scanning results.
5. Understand the reported file and line.
6. Fix the issue if applicable.
7. Push again.

---

### 📚 Tech Jargons Demystified:
- **SAST (Static Application Security Testing):** White-box security scanning inspecting raw uncompiled source code to find security vulnerabilities like SQL injection, cross-site scripting (XSS), path traversal, and memory leaks.
- **CodeQL:** GitHub's semantic code analysis engine that treats code like data, allowing security engineers to query source code syntax trees using declarative object-oriented queries.
- **SARIF (Static Analysis Results Interchange Format):** A standard JSON-based file format used by security scanning tools to report static analysis results to GitHub and IDE dashboards.
- **Taint Analysis / Dataflow Tracking:** Tracking untrusted user input from its entry point (source) across variables and functions until it reaches a dangerous execution sink (e.g. `eval` or raw SQL).

---

## Key Point

SAST is one security layer. A clean SAST result does not mean the complete application is secure.


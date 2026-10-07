# 07 - Secrets

## 1. What is a Secret?

A secret is sensitive information such as:
* Password
* API Token
* Cloud Credential
* Access Key
* Database Password

---

## 2. Create Repository Secret

Go to:
**Repository** → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Create:
* **Name**: `DEMO_SECRET`
* **Value**: `hello-github-actions`

*(For a classroom demo, use a fake value only.)*

---

## 3. Access Secret

Inside the workflow:
```yaml
env:
  DEMO_SECRET: ${{ secrets.DEMO_SECRET }}
```

---

## 4. Do NOT Hardcode Secrets

**Bad:**
```yaml
password: mypassword123
```

**Good:**
```yaml
password: ${{ secrets.MY_PASSWORD }}
```

---

## 5. Do NOT Print Secrets

**Never do:**
```bash
echo "$DEMO_SECRET"
```

**Instead:**
```bash
if [ -n "$DEMO_SECRET" ]; then
  echo "Secret is available."
fi
```

#### 💡 Command Breakdown (cmd-explained):
- `if [ -n "$DEMO_SECRET" ]; then`: Bash conditional test using `-n` ("non-zero length string"). It validates that the variable is set and non-empty without leaking its content to terminal output or logs.
- `echo "Secret is available."`: Emits a safe diagnostic notification confirmative of configuration presence.
- `${{ secrets.DEMO_SECRET }}`: GitHub expression syntax reading encrypted secrets stored in repo settings and binding them to environment variables.

---

## 6. Expected Output

```text
Secret is available.
```

If the secret is missing:
```text
Secret is not configured.
```
The workflow will fail.

---

### 💡 Key Takeaway
> Secrets should be stored securely and injected into workflows only when required.

---

### 📚 Tech Jargons Demystified:
- **Encrypted Secrets:** Values stored securely in GitHub's key vault (using Libsodium sealed boxes) that can only be decrypted at workflow runtime by authorized runners.
- **Log Masking:** GitHub Actions automatically intercepts any workflow log line matching registered secret strings and replaces them with `***` to prevent accidental credential leakage.
- **Environment Scope:** Secrets can be scoped globally to the repository, organization-wide, or strictly restricted to specific environments (like `production` requiring review approvals).
- **Environment Variables (`env:`):** Mapping secrets into environment variables makes them securely accessible to scripts without baking them into command flags.


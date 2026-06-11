# Security Policy

## Supported versions

Dostar is a starter template. Security fixes are applied to the latest version on `main`. There are no maintained release branches.

## Reporting a vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Please report security issues privately via [GitHub Security Advisories](https://github.com/piers-sinclair/Dostar/security/advisories/new).

Include:
- A description of the vulnerability and its potential impact
- Steps to reproduce or a proof-of-concept
- Any suggested mitigations you are aware of

You will receive an acknowledgement within 3 business days. Confirmed vulnerabilities will be patched and disclosed once a fix is available.

## Security model

Dostar is a **template**, not a deployed service. The security guarantees that matter are:

- Template consumers cannot accidentally deploy to the template author's Azure subscription
- No credentials or secrets are embedded in the repository
- The generated infrastructure follows Azure security best practices by default

### What the template provides

- OIDC-only CI/CD (no long-lived service principal secrets)
- PostgreSQL accessible only via private VNet — no public firewall rules
- HTTPS-only Container App ingress (`allowInsecure: false`)
- Security response headers on all API responses
- CORS restricted to the specific frontend origin
- Rate limiting on all API endpoints
- Key Vault for secret storage with RBAC authorization
- Managed identity for ACR and Key Vault access (no embedded credentials)
- Trivy and OpenGrep SAST scans in CI

### What you must do before going to production

See the checklist in [docs/deploy-setup.md](docs/deploy-setup.md#security-checklist).

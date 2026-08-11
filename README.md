# platform-terraform

Shared Terraform modules and environment configs with GitOps via GitHub Actions.

## Structure

```
modules/
  cloud-run-service/   # Reusable Cloud Run module
environments/
  dev/                 # Dev environment config
  staging/             # Staging environment config
  prod/                # Production environment config
```

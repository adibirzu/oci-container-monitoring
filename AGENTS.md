# oci-container-monitoring agent guide
OCI Container Instance monitoring demo with Terraform deployment, container sidecars, and OCI metrics and logs.

## Commands
- Install prerequisites: `./scripts/install-prerequisites.sh` (interactive).
- Configure environment: `./scripts/setup-environment.sh` (writes `config/oci-monitoring.env`).
- Validate Terraform: `./scripts/deploy.sh validate`.
- Plan deployment: `./scripts/deploy.sh plan`.
- Deploy: `./scripts/deploy.sh deploy`.
- Build images: `./docker/build-all.sh --skip-push` (local build; Docker required).
- Run/view: `./scripts/view-logs.sh`; `./scripts/view-metrics.sh`.
- No test suite or lint command is present in this checkout.

## Layout
- `scripts/` — setup, deployment, and OCI metric/log helpers.
- `terraform/` — root OCI resources and Terraform modules.
- `docker/` — image build script, container definitions, and provisioning.
- `config/` — configuration example and checked-in config.
- `docs/` — architecture, monitoring, logging, and troubleshooting guides.
- `output/`, `logs/` — generated deployment outputs and logs.

## Boundaries
- Deployment uses OCI CLI profile `OCI_CLI_PROFILE` (defaults to `DEFAULT` in `scripts/deploy.sh`); configure tenancy, compartment, region, VCN, and subnet in `config/oci-monitoring.env`.
- Do not commit `config/oci-monitoring.env`, credentials, `terraform/terraform.tfstate*`, `terraform/terraform.tfvars`, `terraform/*.tfplan`, `terraform/tfplan`, `terraform/.terraform/`, `output/`, or `logs/` (`.gitignore`).
- `scripts/setup-environment.sh` generates `config/oci-monitoring.env`; `docker/build-all.sh` updates image URLs there; deployment generates Terraform variable files and output artifacts.

## On error
Search KB.md (and ~/dev/OCI-DEMO/KB.md for OCI issues) before debugging; add an entry after a new fix. Do not read KB.md at session start.

## Done
Run `./scripts/deploy.sh validate`.

<!-- BEGIN oci4cca-ecosystem-matrix -->
Shared OCI4CCA ownership/interconnect contract: [docs/OCI4CCA_ECOSYSTEM.md](docs/OCI4CCA_ECOSYSTEM.md), generated from OCI-DEMO `config/oci4cca_ecosystem.json`. Read it only for cross-project work.
<!-- END oci4cca-ecosystem-matrix -->

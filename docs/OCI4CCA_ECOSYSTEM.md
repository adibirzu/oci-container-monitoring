# OCI4CCA shared ecosystem contract

<!-- BEGIN oci4cca-ecosystem-matrix -->
## OCI4CCA ecosystem: ownership and interconnect

Independent accelerators; not Oracle products or official Oracle deliverables.
Topology evidence date: 2026-10-21. Service DNS/ports observed in selected OKE cluster; public hostnames are portable configuration contracts, not ingress acceptance. Empty runtime fields mean not discovered, not absent.

Thirteen logical projects; the Forge baseline has two separate repository checkouts.
Do not apply a sibling project's tenancy or cluster policy to this project.

| Project / local checkout | OKE namespace and service URL | Public ingress contract | Role | Upstream / downstream |
| --- | --- | --- | --- | --- |
| `OCI-DEMO`: `~/dev/OCI-DEMO` | `control-plane`<br>http://control-plane.control-plane.svc.cluster.local:80 | `https://cp.<DNS_DOMAIN>` | Control Plane, cyber ranges, Caldera, Guacamole, detection orchestration | Consumes all suite contracts; orchestrates approved work and detection reads |
| `ObserveAI`: `~/dev/ObserveAI` | `observeai`<br>http://observeai.observeai.svc.cluster.local:3000<br>http://observeai-backend.observeai.svc.cluster.local:8000 | `https://observeai.<DNS_DOMAIN>` | MELTS observability, APM, globe and Network Beacon & C2 Threat Hunting | Reads LA/APM/Monitoring and baseline catalog; exchanges bounded findings with Guardian/Coordinator when configured |
| `oci-guardian`: `~/dev/oci-guardian` | `guardian`<br>http://guardian.guardian.svc.cluster.local:80 | `https://guardian.<DNS_DOMAIN>` | CSPM, CMDB graph, RedAmon, IAM policy review and CIS scans | Reads OCI inventory/security; consumes baseline; posture interconnect with Compliance requires tenant/provenance evidence |
| `oci-compliance-scanner`: `~/dev/oci-compliance-scanner` | `compliance`<br>http://compliance-scanner.compliance.svc.cluster.local:80 | `https://compliance.<DNS_DOMAIN>` | Compliance collection and ten-framework suite catalog | Consumes provider evidence; peer health adapter checks Guardian/ObserveAI/CP; scores require versioned collection |
| `logan-security-dashboard`: `~/dev/logan-security-dashboard`<br>`LoganSecurityDashboardv0`: `~/dev/LoganSecurityDashboardv0` | `logan-forge`<br>http://logan-forge.logan-forge.svc.cluster.local:3000 | `https://forge.<DNS_DOMAIN>` | Baseline rules catalog; Sigma-to-OCL and network hunting assets | Exports baseline to CP/ObserveAI/Guardian; Forge presentation also consumes oci-log-analytics-detections; alias is a separate checkout, not proof of deployment parity |
| `oci-coordinator`: `~/dev/oci-coordinator` | `oci-ai`<br>http://oci-coordinator.oci-ai.svc.cluster.local:80<br>http://coordinator-page.oci-ai.svc.cluster.local:8501 | `https://coordinator.<DNS_DOMAIN>` | Multi-agent investigation, SQLcl/Log Analytics MCP and guarded SOAR | Consumes approved evidence and discovered MCP contracts; ZPR/NSG containment requires separate exact approval |
| `oci-zpr-visibility`: `~/dev/oci-zpr-visibility` | Not discovered; collector/library/report assets, not an assumed web service | No ingress contract discovered | ZPR security attribute discovery, flow correlation and snapshot drift | Reads OCI attributes/VCN flows; uploads configured inventory to LA; downstream CMDB/globe and simulation/quarantine remain proposed or unverified |
| `gcplogs2oci`: `~/dev/gcplogs2oci` | Not discovered; collector/library/report assets, not an assumed web service | No ingress contract discovered | GCP Cloud Audit, VPC Flow and GKE log bridge | Cloud Logging -> Pub/Sub -> bridge -> OCI Streaming -> Service Connector Hub -> LA |
| `azurelogs2oci`: `~/dev/azurelogs2oci` | Not discovered; collector/library/report assets, not an assumed web service | No ingress contract discovered | Azure Activity, Entra ID, NSG Flow and Defender bridge | Event Hubs -> Azure Function -> OCI Streaming -> Service Connector Hub -> LA; source-category coverage requires delivery receipts |
| `oci-metrics-report`: `~/dev/oci-metrics-report` | Not discovered; collector/library/report assets, not an assumed web service | No ingress contract discovered | OCI Monitoring MQL capacity/performance and executive reports | Reads Monitoring; generates reports; not itself a telemetry-ingestion bridge |
| `octo-observability-demo`: `~/dev/octo-observability-demo` | Not discovered; collector/library/report assets, not an assumed web service | No ingress contract discovered | Full-stack OTel, OCI APM traces and RUM demonstration | Instrumented applications -> APM/logging/Monitoring when configured; separate tenancy/cluster boundaries must be preserved |
| `oci-container-monitoring`: `~/dev/oci-container-monitoring` | Not discovered; collector/library/report assets, not an assumed web service | No ingress contract discovered | OKE Management Agent, Fluentd and Prometheus/OTel telemetry assets | OKE telemetry -> configured Monitoring/LA destinations; exact namespaces and log delivery require separate verification |
| `oci-log-analytics-detections`: `~/dev/oci-log-analytics-detections` | Not discovered; collector/library/report assets, not an assumed web service | No ingress contract discovered | OCI LA detections, saved searches and curated hunts | Owns query sources/generators/catalogs; Forge and CP consume reviewed artifacts; provider execution requires approval |

### Data and control flows

- **Multi-cloud and OKE telemetry:** GCP Cloud Logging (Cloud Audit, VPC Flow,
  GKE when configured) -> Pub/Sub -> gcplogs2oci -> OCI Streaming -> Service
  Connector Hub -> OCI Log Analytics. Azure Event Hubs (Activity, Entra ID,
  NSG Flow, Defender when configured) -> Azure Function in azurelogs2oci ->
  OCI Streaming -> Service Connector Hub -> Log Analytics. AWS collectors are
  separately owned/configured dependencies, not a fourteenth suite project.
  oci-container-monitoring supplies Management Agent/Fluentd/Prometheus/OTel
  assets; octo-observability-demo supplies configured APM traces and RUM.
  oci-metrics-report reads Monitoring MQL and produces capacity, performance
  and executive reports. Logs, metrics, traces and RUM remain distinct paths;
  successful collection, indexing and cross-signal joins need separate receipts.
- **Zero trust and network hunting:** oci-zpr-visibility inventories attributes
  and correlates VCN Flow Logs with policy intent and snapshot drift. Search
  names `zpr-visibility-web` and `zpr-visibility-db` are discovery hints, not
  proof of resource type, coverage or a fresh inventory. ObserveAI
  `/observability/globe` and Forge expose Network Beacon & C2 Threat Hunting
  surfaces for periodicity, JA3/TLS, DNS tunneling and east-west flow analysis
  when their sources/fields exist. Availability of each analytic is separately
  evidenced. Flow rejects do not identify ZPR as the cause. Cross-app joins,
  blast-radius simulation and ZPR attribute quarantine remain proposed or
  unverified until target-bound receipts establish them.
- **Posture and assets:** Guardian `/cmdb/assets?view=graph`, `/redamon`,
  `/policy-reviewer` and `/scan` own inventory, discovery, IAM policy review
  and CIS scan views. A 201+ asset count and Llama 3.3 70B are brief/configuration
  targets, not guaranteed current inventory or model availability. Discover the
  active provider/model at runtime. Compliance's suite catalog lists CIS OCI,
  ISO 27001, NIST 800-53, PCI-DSS, SOC 2, HIPAA, GDPR, DORA, NIST AI RMF and
  EU AI Act. Catalog presence or peer health does not prove ten evaluations;
  sample seed scores cannot become provider evidence. Tenant-bound posture
  exchange requires provenance, framework version and collection timestamps.
- **Range, detection and triage:** Control Plane `/remote`, `/caldera`,
  `/threat-hunting`, `/attack-logs` and `/detections` coordinate configured
  Guacamole, Caldera/Sandcat, attack-log reads and detection artifacts. Private
  HexStrike service `http://observeai-t3mp3st.observeai.svc.cluster.local:3333`
  is a discovered endpoint, not authority to run recon. Forge, ObserveAI and
  Coordinator consume bounded artifacts/findings for investigation. SQLcl and
  Log Analytics MCP require runtime schema/auth discovery. Caldera operations,
  recon, SOAR and ZPR/NSG containment require named authorization, exact target,
  time window, least privilege, audit and rollback; never auto-execute from a
  detection, model suggestion, dashboard link or this topology document.

### Artifact ownership and safe synchronization

- `logan-security-dashboard/scripts/export_detection_catalog.py` owns the
  baseline export. OCI-DEMO `config/logan_security_dashboard_rules.json`,
  ObserveAI `backend/data/logan_security_dashboard_rules.json`, and Guardian
  `data/logan_security_dashboard_rules.json` must be byte-identical. The current
  source has 200 entries and five unique rule queries; preserve provenance and
  `provider_validation: unverified`. These are not 200 independently validated
  detections. `oci-log-analytics-detections` owns its separate generated catalogs
  and curated hunts; do not overwrite one with the other.
- Canonical architecture contracts in `~/dev/OCI-DEMO/docs/architecture/`:
  [unified design](../../OCI-DEMO/docs/architecture/OCI4CCA_UNIFIED_DESIGN_AND_INTERCONNECT.md)
  and [ZPR workflow](../../OCI-DEMO/docs/architecture/OCI_ZPR_VISIBILITY_WORKFLOW_AND_ARCHITECTURE.md).
  From this repository root use those sibling paths (the links are navigation
  hints; the local summary in `docs/OCI4CCA_ECOSYSTEM.md` remains available).
  Unified design distinguishes six-product presentation from unimplemented
  event exchange. ZPR separates inventory, flow inference, upload/drift evidence
  and proposed response. Missing/stale owner checkouts remain unavailable.
- OCI-DEMO's `external-projects.yaml` and current sync/materialization scripts
  own pinned external mirrors. Never rsync a dirty checkout over a verified
  snapshot, copy env files/databases/wallets/browser state, or silently repin.
  Commit/review the owner artifact, reconcile the pin under its contract, then
  materialize and validate its content-bound receipt. Preserve existing mirrors
  on conflict. A refreshed mirror does not prove publication or deployment.
- Requested operational sync surfaces: CP `POST /api/guacamole/sync` updates
  configured Guacamole targets; `GET /api/detections/ecosystem-summary` reads
  bounded service/catalog status. Compliance `POST /api/interconnect/sync`
  refreshes cached peer health only. These calls do not replicate tenant asset,
  finding, framework or event databases. Use configured server-side credentials;
  do not forward browser tokens between peers or weaken authentication.
- Re-run `python3.11 scripts/sync_ecosystem_contracts.py --check` from the
  designated OCI-DEMO source worktree with sibling checkouts available. It
  verifies only managed docs/catalog copies. Keep credentials, real OCIDs,
  public IPs, namespaces and runtime data out of commits. Classify source,
  configured, locally verified, provider verified and release accepted claims
  independently; empty/unavailable sources must carry their reason.

<!-- END oci4cca-ecosystem-matrix -->

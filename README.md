# CSCI-8420 — Group 2

Software security engineering analysis of **[CrowdSec](https://github.com/crowdsecurity/crowdsec)**,
an open-source, collaborative intrusion detection and remediation engine, modeled in a
hypothetical enterprise network (multi-server LAPI) environment.

## Team

| Name | Role |
|---|---|
| Leonard Meredith | Team Lead |
| Kowshik Chowdhury | Member |
| Mujib Latifi | Member |
| Trung Phan | Member |
| Hrudhay Rao Chepyala | Member |

## Quick Links

- 📄 [Project Proposal](Proposal.md)
- 🛡️ [Requirements for Software Security Engineering](Requirements%20for%20SSE.md) — use/misuse case analysis
- 📋 [Project Board](https://github.com/users/StevePhan412/projects/1)
- 📚 [Wiki](../../wiki) — team roles, workflow norms, decisions log
- 🐛 [Open Issues](../../issues)
  
## Status

- [x] GitHub backend infrastructure (repo, board, labels, wiki)
- [x] Open-source project selection
- [x] Project proposal — software description, systems engineering view, threats, security features, license, security history, reflections
- [x] Essential interactions with the operational environment (Issues #1 & #2)
- [x] Use/misuse case analysis for five use cases with derived security requirements (Issue #3)
- [x] AI-assisted iteration and final use/misuse diagram (Issue #4)

## Repository Contents

| Path | Contents |
|---|---|
| [`Proposal.md`](Proposal.md) | Project proposal: CrowdSec overview, systems engineering view, threats and security features, license and contribution process, security advisories, team reflections |
| [`Requirements for SSE.md`](Requirements%20for%20SSE.md) | Essential interactions, misuser catalog, use/misuse cases UC-1 – UC-5, coverage check, derived security requirements, AI-assisted review |
| [`resources/static/`](resources/static) | Systems engineering diagram and use-case diagrams (PNG exports and `.drawio` sources) |
| [`resources/static/issue3-4/`](resources/static/issue3-4) | Per-use-case use/misuse diagrams, the final combined diagram, and the editable `CrowdSec_Use_Misuse_Cases.drawio` |
| [`.github/workflows/blank.yml`](.github/workflows/blank.yml) | CI: markdown link checking and linting on every push/PR to `main` |

### Use cases analyzed

| # | External actor | Use case (CrowdSec feature) |
|---|---|---|
| UC-1 | Enterprise Log Source | Ingest & Analyze Logs — acquisition, parsers, scenarios |
| UC-2 | Web App / Reverse Proxy | Inspect HTTP Request — AppSec / WAF |
| UC-3 | Remediation Component (bouncer) | Retrieve & Enforce Decisions — LAPI decisions API |
| UC-4 | SOC Administrator | Manage Policy & Detection Content — cscli, Hub, allowlists |
| UC-5 | CrowdSec Central API (CAPI) | Exchange Threat Intelligence — signals and community blocklist |

Diagrams can be edited by opening the `.drawio` files in [app.diagrams.net](https://app.diagrams.net)
(*File → Open from → Device*).

## How We Work

Every task is tracked as a GitHub Issue linked to a card on the Project Board.
Before an issue is closed, it should have a comment summarizing what was done and
at least one teammate's review. See the [Wiki](../../wiki) for full workflow
norms, meeting notes, and the decisions log.

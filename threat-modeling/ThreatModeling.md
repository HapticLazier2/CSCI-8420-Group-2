# Threat Modeling — CrowdSec Security Engine
**CSCI-8420 Software Security Engineering · Group 2**
Leonard Meredith (lead) · Kowshik Chowdhury · Mujib Latifi · Trung Phan · Hrudhay Rao Chepyala

<!-- Replace OWNER/REPO everywhere below. Delete HTML comments before submitting. -->

## Contents
1. [Part 1: Threat Modeling](#part-1-threat-modeling)
   - [Scenario-to-DFD mapping](#scenario-to-dfd-mapping)
   - [DFD-1: Detection pipeline](#dfd-1-detection-pipeline)
   - [DFD-2: Remediation path and authentication](#dfd-2-remediation-path-and-authentication)
   - [DFD-3: External and cloud services](#dfd-3-external-and-cloud-services)
   - [Cross-boundary threat summary](#cross-boundary-threat-summary)
   - [AI analysis vs TMT](#ai-analysis-vs-tmt-optional)
2. [Part 2: Observations](#part-2-observations)
   - [Mitigation review](#mitigation-review)
   - [Gaps](#gaps)
   - [Team collaboration](#team-collaboration)
   - [Reflection](#reflection)

---

## Part 1: Threat Modeling

**Approach.** We modeled CrowdSec as three DFDs that together cover all of our prioritized scenarios from the Security Requirements and Assurance Case assignments. Each was drawn and analyzed in the Microsoft Threat Modeling Tool using the *SDL TM Knowledge Base (Core)* template. Shared conventions (element names, trust boundaries, triage format) are in [`threat-model/CONVENTIONS.md`](threat-model/CONVENTIONS.md).

**Trust boundaries used across all diagrams**

| Boundary | Separates |
|---|---|
| Internet Boundary | Public internet (CAPI, Console, Hub, attackers) from the deployment |
| LAPI Host Boundary | The machine running LAPI and its database from everything else |
| Remote Host Boundary | Bouncers/agents on other machines from the LAPI host |
| Privilege Boundary | Root-only resources (credentials, `cscli`) from unprivileged processes |

### Scenario-to-DFD mapping

| Scenario (from earlier assignments) | Misuse case / assurance claim | DFD | Key flows |
|---|---|---|---|
| <!-- e.g. Attacker forges decisions to unblock own IP --> | <!-- MUC-x / C1 --> | DFD-2 | LAPI → Bouncer |
| | | | |

### DFD-1: Detection pipeline
*Owner: Kowshik Chowdhury*

![DFD-1](threat-model/images/dfd1.png)

**Full TMT report:** [View HTML report](https://htmlpreview.github.io/?https://github.com/OWNER/REPO/blob/main/threat-model/reports/dfd1.htm) · [Model file](threat-model/dfd1-detection/dfd1-detection.tm7)

**Scope.** <!-- 2–3 sentences: elements, boundaries, which scenarios -->

**Triage summary**

| STRIDE | Generated | Mitigated | Not Applicable | Needs Investigation |
|---|---|---|---|---|
| Spoofing | | | | |
| Tampering | | | | |
| Repudiation | | | | |
| Information Disclosure | | | | |
| Denial of Service | | | | |
| Elevation of Privilege | | | | |
| **Total** | | | | |

**Mitigations for relevant threats**

| ID | Threat (STRIDE) | Element / flow | XB? | Mitigation | Layer | Quick win / structural |
|---|---|---|---|---|---|---|
| D1-01 | | | | | | |

### DFD-2: Remediation path and authentication
*Owner: Mujib Latifi*

![DFD-2](threat-model/images/dfd2.png)

**Full TMT report:** [View HTML report](https://htmlpreview.github.io/?https://github.com/OWNER/REPO/blob/main/threat-model/reports/dfd2.htm) · [Model file](threat-model/dfd2-remediation/dfd2-remediation.tm7)

**Scope.**

**Triage summary**

| STRIDE | Generated | Mitigated | Not Applicable | Needs Investigation |
|---|---|---|---|---|
| Spoofing | | | | |
| Tampering | | | | |
| Repudiation | | | | |
| Information Disclosure | | | | |
| Denial of Service | | | | |
| Elevation of Privilege | | | | |
| **Total** | | | | |

**Mitigations for relevant threats**

| ID | Threat (STRIDE) | Element / flow | XB? | Mitigation | Layer | Quick win / structural |
|---|---|---|---|---|---|---|
| D2-01 | | | | | | |

### DFD-3: External and cloud services
*Owner: Trung Phan*

![DFD-3](/threat-modeling/dfd3-external/dfd3-external-cloud.png)

**Full TMT report:** [View HTML report](https://htmlpreview.github.io/?https://github.com/OWNER/REPO/blob/main/threat-model/reports/dfd3.htm) · [Model file](threat-model/dfd3-external/dfd3-external.tm7)

**Scope.** This diagram models the external and cloud interactions for the CrowdSec Security Engine across the Internet Boundary, LAPI Host Boundary, and Privilege Boundary. It covers bidirectional signal sharing (offender IPs) and community blocklist synchronization between the Local API (LAPI) and Central API (CAPI), instance enrollment and telemetry reporting to the Online Console, and `cscli` interactions with the CrowdSec Hub to download and store parsers, scenarios, and collections into Hub Configs and LAPI DB.

**Triage summary**

| STRIDE | Generated | Mitigated | Not Applicable | Needs Investigation |
|---|---|---|---|---|
| Spoofing | 6 | 6 | 0 | 0 |
| Tampering | 3 | 3 | 0 | 0 |
| Repudiation | 5 | 5 | 0 | 0 |
| Information Disclosure | 1 | 1 | 0 | 0 |
| Denial of Service | 7 | 7 | 0 | 0 |
| Elevation of Privilege | 5 | 5 | 0 | 0 |
| **Total** | **27** | **27** | **0** | **0** |

**Mitigations for relevant threats**

| ID | Threat (STRIDE) | Element / flow | XB? | Mitigation | Layer | Quick win / structural |
|---|---|---|---|---|---|---|
| D3-01 | Elevation Using Impersonation (EoP) | `control` (Crowdsec CLI → LAPI) | Yes | Require TLS certificate authentication before access | Application / Network | Structural |
| D3-02 | Authenticated Data Flow Compromised (T) | `control` (Crowdsec CLI → LAPI) | Yes | Enforce HTTPS (TLS 1.2 or higher) for all REST API communications | Network | Quick win |
| D3-03 | Data Flow Is Potentially Interrupted (DoS) | `Download parsers and scenarios` (Crowdsec Hub → Crowdsec CLI) | Yes | Implement automated cron jobs with retry logic to periodically run `cscli` updates to ensure configurations stay current | Operations | Quick win |
| D3-04 | External Entity Potentially Denies Receiving Data (R) | `Download parsers and scenarios` (Crowdsec Hub → Crowdsec CLI) | Yes | Monitor and audit `cscli` execution logs and retry if needed | Operations / Application | Quick win |
| D3-05 | Data Flow Is Potentially Interrupted (DoS) | `Enrollment and Telemetry` (LAPI → Online console) | Yes | Configure LAPI to queue console telemetry locally and retry transmission automatically when network connection is restored | Application | Structural |
| D3-06 | External Entity Potentially Denies Receiving Data (R) | `Enrollment and Telemetry` (LAPI → Online console) | Yes | Log successful telemetry transmissions and enrollment handshakes locally on LAPI | Application | Quick win |
| D3-07 | Spoofing of External Destination Entity (S) | `Enrollment and Telemetry` (LAPI → Online console) | Yes | Require TLS certificate authentication before access | Network / Application | Quick win |
| D3-08 | Data Flow Is Potentially Interrupted (DoS) | `Request config` (Crowdsec CLI → Crowdsec Hub) | Yes | Ensure resilient outbound network routing and implement retry logic for `cscli hub update` commands | Operations / Network | Quick win |
| D3-09 | External Entity Potentially Denies Receiving Data (R) | `Request config` (Crowdsec CLI → Crowdsec Hub) | Yes | Enable detailed local logging of all outbound HTTP requests and response codes from `cscli` to the Hub | Application | Quick win |
| D3-10 | Data Flow Is Potentially Interrupted (DoS) | `Send offender IPs` (LAPI → CAPI) | Yes | Configure LAPI to locally queue and cache offender IPs during network outages, transmitting them when connectivity is restored | Application | Structural |
| D3-11 | External Entity Potentially Denies Receiving Data (R) | `Send offender IPs` (LAPI → CAPI) | Yes | Log HTTP 200 OK responses in LAPI after successfully pushing offender IP signals | Application | Quick win |
| D3-12 | Spoofing of External Destination Entity (S) | `Send offender IPs` (LAPI → CAPI) | Yes | Enforce strict TLS certificate validation (verifying the CA chain) in the LAPI when pushing signals | Network / Application | Quick win |
| D3-13 | Spoofing of Destination Data Store (S) | `store` (Crowdsec CLI → Hub Configs) | No | Enforce strict file system permissions | OS / Host | Quick win |
| D3-14 | Spoofing of Destination Data Store (S) | `store` (LAPI → LAPI DB) | No | Restrict OS-level file permissions or use strong authentication for DB | OS / Database | Quick win |
| D3-15 | Potential Excessive Resource Consumption (DoS) | `store` (LAPI → LAPI DB) | No | Limit resource usage for each connection at the OS level | OS / Host | Structural |
| D3-16 | Authenticated Data Flow Compromised (T) | `store` (LAPI → LAPI DB) | No | Enforce HTTPS (TLS 1.2 or higher) for all REST API communications | Network | Quick win |
| D3-17 | Cross Site Request Forgery (EoP) | `Transfer community blocklist` (CAPI → LAPI) | Yes | Apply input validation and sanitize with escape characters; rely strictly on auth headers (API keys/tokens) for M2M traffic and reject session cookies | Application | Structural |
| D3-18 | Elevation by Changing Execution Flow in LAPI (EoP) | `Transfer community blocklist` (CAPI → LAPI) | Yes | Apply input validation on all external data and ensure LAPI operates with OS-level exploit mitigations enabled | Application / OS | Structural |
| D3-19 | Elevation of Privilege Using Remote Code Execution (EoP) | `Transfer community blocklist` (CAPI → LAPI) | Yes | Keep CAPI software updated and implement least-privilege processes for all users | Operations / OS | Structural |
| D3-20 | Elevation Using Impersonation (EoP) | `Transfer community blocklist` (CAPI → LAPI) | Yes | Validate TLS certificates and check payload signatures where applicable | Application / Network | Structural |
| D3-21 | Data Flow Is Potentially Interrupted (DoS) | `Transfer community blocklist` (CAPI → LAPI) | Yes | Cache most recent downloaded community blocklist in local LAPI DB so enforcement continues during cloud outages | Application | Structural |
| D3-22 | Potential Process Crash or Stop for LAPI (DoS) | `Transfer community blocklist` (CAPI → LAPI) | Yes | Manage LAPI with a process manager (`systemd`) with an automatic restart policy and monitor service uptime | Operations / OS | Quick win |
| D3-23 | Data Flow Sniffing (I) | `Transfer community blocklist` (CAPI → LAPI) | Yes | Enforce HTTPS (TLS 1.2 or higher) for all REST API communications | Network | Quick win |
| D3-24 | Potential Data Repudiation by LAPI (R) | `Transfer community blocklist` (CAPI → LAPI) | Yes | Enable detailed audit logging in LAPI to record the receipt, timestamp, and summary of all downloaded community blocklists | Application | Quick win |
| D3-25 | Potential Lack of Input Validation for LAPI (T) | `Transfer community blocklist` (CAPI → LAPI) | Yes | Apply input validation for any HTTP request to LAPI and sanitize JSON/YAML blocklist payloads before writing to the database | Application | Structural |
| D3-26 | Spoofing the CAPI External Entity (S) | `Transfer community blocklist` (CAPI → LAPI) | Yes | Enforce strict TLS certificate validation in LAPI to ensure it only pulls blocklists from legitimate CrowdSec CAPI | Network / Application | Quick win |
| D3-27 | Spoofing the LAPI Process (S) | `Transfer community blocklist` (CAPI → LAPI) | Yes | Require strong, unique API keys for LAPI authentication to CAPI | Application | Quick win |

### Cross-boundary threat summary
<!-- Lead: pull every [XB] threat from the three tables. This is the section graders look for. -->

| ID | Boundary crossed | Flow | Threat | Mitigation | Priority |
|---|---|---|---|---|---|
| D3-01 | Privilege / LAPI Host Boundary | `control` (Crowdsec CLI → LAPI) | Elevation Using Impersonation (EoP) | Require TLS cert auth before access | High |
| D3-02 | Privilege / LAPI Host Boundary | `control` (Crowdsec CLI → LAPI) | Authenticated Data Flow Compromised (T) | Enforce HTTPS (TLS 1.2+) for all REST API communications | High |
| D3-03 | Internet Boundary | `Download parsers and scenarios` (Crowdsec Hub → Crowdsec CLI) | Data Flow Interrupted (DoS) | Automated cron jobs with retry logic for `cscli` updates | High |
| D3-04 | Internet Boundary | `Download parsers and scenarios` (Crowdsec Hub → Crowdsec CLI) | External Entity Denies Receiving Data (R) | Monitor and audit `cscli` execution logs; retry if needed | High |
| D3-05 | Internet / LAPI Host Boundary | `Enrollment and Telemetry` (LAPI → Online console) | Data Flow Interrupted (DoS) | Queue console telemetry locally and retry automatically when restored | High |
| D3-06 | Internet / LAPI Host Boundary | `Enrollment and Telemetry` (LAPI → Online console) | External Entity Denies Receiving Data (R) | Log successful telemetry transmissions and enrollment handshakes locally | High |
| D3-07 | Internet / LAPI Host Boundary | `Enrollment and Telemetry` (LAPI → Online console) | Spoofing of Online console (S) | Require TLS cert auth before access | High |
| D3-08 | Internet Boundary | `Request config` (Crowdsec CLI → Crowdsec Hub) | Data Flow Interrupted (DoS) | Ensure resilient outbound routing and retry logic for `cscli hub update` | High |
| D3-09 | Internet Boundary | `Request config` (Crowdsec CLI → Crowdsec Hub) | External Entity Denies Receiving Data (R) | Enable detailed local logging of outbound HTTP requests/responses | High |
| D3-10 | Internet / LAPI Host Boundary | `Send offender IPs` (LAPI → CAPI) | Data Flow Interrupted (DoS) | Locally queue and cache offender IPs during outages; transmit when restored | High |
| D3-11 | Internet / LAPI Host Boundary | `Send offender IPs` (LAPI → CAPI) | External Entity Denies Receiving Data (R) | Log HTTP 200 OK responses in LAPI after pushing offender IP signals | High |
| D3-12 | Internet / LAPI Host Boundary | `Send offender IPs` (LAPI → CAPI) | Spoofing of CAPI Destination (S) | Enforce strict TLS certificate validation (CA chain) when pushing signals | High |
| D3-17 | Internet / LAPI Host Boundary | `Transfer community blocklist` (CAPI → LAPI) | Cross Site Request Forgery (EoP) | Input validation/escaping; rely strictly on API key/token headers, reject cookies | High |
| D3-18 | Internet / LAPI Host Boundary | `Transfer community blocklist` (CAPI → LAPI) | Elevation by Changing Execution Flow (EoP) | Input validation on external data and OS-level exploit mitigations enabled | High |
| D3-19 | Internet / LAPI Host Boundary | `Transfer community blocklist` (CAPI → LAPI) | Elevation Using RCE (EoP) | Keep CAPI software updated and enforce least-privilege processes | High |
| D3-20 | Internet / LAPI Host Boundary | `Transfer community blocklist` (CAPI → LAPI) | Elevation Using Impersonation (EoP) | Validate TLS certificates and check payload signatures where applicable | High |
| D3-21 | Internet / LAPI Host Boundary | `Transfer community blocklist` (CAPI → LAPI) | Data Flow Interrupted (DoS) | Cache most recent community blocklist in local LAPI DB for offline enforcement | High |
| D3-22 | Internet / LAPI Host Boundary | `Transfer community blocklist` (CAPI → LAPI) | Process Crash or Stop for LAPI (DoS) | Manage LAPI with `systemd` automatic restart policy and monitor uptime | High |
| D3-23 | Internet / LAPI Host Boundary | `Transfer community blocklist` (CAPI → LAPI) | Data Flow Sniffing (I) | Enforce HTTPS (TLS 1.2+) for all REST API communications | High |
| D3-24 | Internet / LAPI Host Boundary | `Transfer community blocklist` (CAPI → LAPI) | Data Repudiation by LAPI (R) | Detailed audit logging in LAPI for receipt, timestamp, and summary of blocklists | High |
| D3-25 | Internet / LAPI Host Boundary | `Transfer community blocklist` (CAPI → LAPI) | Lack of Input Validation for LAPI (T) | Validate HTTP requests and sanitize JSON/YAML blocklist payloads before DB write | High |
| D3-26 | Internet / LAPI Host Boundary | `Transfer community blocklist` (CAPI → LAPI) | Spoofing CAPI External Entity (S) | Enforce strict TLS certificate validation in LAPI when pulling blocklists | High |
| D3-27 | Internet / LAPI Host Boundary | `Transfer community blocklist` (CAPI → LAPI) | Spoofing the LAPI Process (S) | Require strong, unique API keys for LAPI authentication to CAPI | High |

**Design guardrails.**
- **Enforced HTTPS (TLS 1.2+) with strict certificate/TLS validation and header-only API authentication across all cross-boundary flows:** Requiring verified TLS certificates (CA chain validation for `CAPI`, `Online console`, and `Crowdsec Hub`, plus client certificates or unique API keys via headers for `LAPI` and `cscli`) and rejecting browser session cookies eliminates entire classes of network sniffing (`I`), MitM tampering (`T`), endpoint spoofing (`S`), and CSRF (`E`) threats (mitigating D3-01, D3-02, D3-07, D3-12, D3-16, D3-17, D3-20, D3-23, D3-26, D3-27).
- **Strict schema validation and payload sanitization at all ingestion boundaries:** Validating and sanitizing all inbound JSON/YAML payloads (community blocklists from `CAPI`, parsers/scenarios from `Crowdsec Hub`) before database insertion or execution prevents injection, remote code execution, and control-flow tampering (`T`, `E`) across LAPI and local data stores (mitigating D3-17, D3-18, D3-25).
- **Local caching, asynchronous queueing, and automated retry with service supervision:** Caching community blocklists in `LAPI DB`, queueing outbound offender IP signals and console telemetry during cloud outages, and managing `LAPI` and `cscli` updates via `systemd` restart policies and retry-enabled cron jobs neutralize external availability disruptions and process crashes (`D`) (mitigating D3-03, D3-05, D3-08, D3-10, D3-21, D3-22).
- **OS-level least privilege, file permission lockdown, and audit logging:** Running CrowdSec services under least-privilege accounts with restricted file permissions on `LAPI DB` and `Hub Configs`, paired with comprehensive local logging of all REST handshakes and `cscli` updates, eliminates local data store spoofing (`S`), resource exhaustion (`D`), and cross-boundary repudiation (`R`) (mitigating D3-04, D3-06, D3-09, D3-11, D3-13, D3-14, D3-15, D3-19, D3-24).

### AI analysis vs TMT (optional)
*Owner: Hrudhay Rao Chepyala*

We ran the instructor's STRIDE-per-Interaction prompt on each final DFD. Raw outputs: [`threat-model/ai/`](threat-model/ai/).

| DFD | Found by both | TMT only | AI only | AI noise / incorrect |
|---|---|---|---|---|
| DFD-1 | | | | |
| DFD-2 | | | | |
| DFD-3 | | | | |

**What each approach missed.** <!-- short paragraph -->

**Top 10 threats by likelihood × impact**

| Rank | ID | Threat | Likelihood | Impact | Rationale |
|---|---|---|---|---|---|
| 1 | | | | | |

**Derived test cases / requirements (optional)**

| Threat ID | Abuse test or requirement |
|---|---|
| | |

---

## Part 2: Observations

### Mitigation review
*Consolidated by Hrudhay Rao Chepyala from each DFD owner's code review.*

We checked the CrowdSec source, documentation and default configuration for each expected mitigation.

| Mitigation ID | Expected control | Status | Evidence | Notes |
|---|---|---|---|---|
| D2-xx | | Present / Partial / Absent | [link]() | |

**Summary:** <!-- X of Y expected mitigations present, Z partial, W absent -->

### Gaps
<!-- Highlight: each Absent/Partial item, why it matters, which threat stays open. Separate "secure option exists but not default" from "not implemented". -->

| Gap | Threat left open | Default config or missing in code? | Impact | Recommendation |
|---|---|---|---|---|
| | | | | |

### Team collaboration
Task assignments, issues and progress: **[Project board](https://github.com/users/OWNER/projects/N)** · [Issues for this assignment](https://github.com/OWNER/REPO/issues?q=label%3Athreat-model)

| Member | Responsibilities |
|---|---|
| Leonard Meredith | Lead: conventions, boundary review, report hosting, assembly, submission |
| Kowshik Chowdhury | DFD-1 detection pipeline, TMT analysis, Part 2 code review |
| Mujib Latifi | DFD-2 remediation & auth, TMT analysis, Part 2 code review |
| Trung Phan | DFD-3 external/cloud, TMT analysis, Part 2 code review |
| Hrudhay Rao Chepyala | AI STRIDE analysis & comparison, prioritization, Part 2 consolidation |

### Reflection
<!-- Lead: compile from the reflections issue. Organize by theme, not by person; attribute specific points where it helps. -->

**What we learned**

**What we found most useful**

**What we would do differently**

---

<!--
SUBMISSION CHECKLIST (delete before submitting)
Part 1
[ ] DFDs cover every prioritized scenario (mapping table filled)
[ ] Diagrams drawn and analyzed in TMT; final Level 1/2 only triaged
[ ] Every generated threat has a state + justification
[ ] Mitigations documented for relevant threats
[ ] Cross-boundary threats called out
[ ] Full HTML report per DFD, hosted in repo, htmlpreview links tested in a private window
[ ] (Optional) AI comparison done
Part 2
[ ] Mitigation review with evidence links
[ ] Gaps highlighted
[ ] Link to GitHub repo/board showing assignments and collaboration
[ ] Team reflection compiled from individual reflections
Submission
[ ] OWNER/REPO and project number replaced everywhere
[ ] All images render on GitHub
[ ] Canvas submission = link to this file
-->

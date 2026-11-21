# Threat Modeling — CrowdSec Security Engine
**CSCI-8420 Software Security Engineering · Group 2**
Leonard Meredith (lead) · Kowshik Chowdhury · Mujib Latifi · Trung Phan · Hrudhay Rao Chepyala

## Contents
1. [Part 1: Threat Modeling](#part-1-threat-modeling)
   - [Scenario-to-DFD mapping](#scenario-to-dfd-mapping)
   - [DFD-1: Detection pipeline](#dfd-1-detection-pipeline)
   - [DFD-2: Remediation path and authentication](#dfd-2-remediation-path-and-authentication)
   - [DFD-3: External and cloud services](#dfd-3-external-and-cloud-services)
   - [Cross-boundary threat summary](#cross-boundary-threat-summary)
   - [AI analysis vs TMT](#ai-analysis-vs-tmt)
2. [Part 2: Observations](#part-2-observations)
   - [Mitigation review](#mitigation-review)
   - [Gaps](#gaps)
   - [Team collaboration](#team-collaboration)
   - [Reflection](#reflection)

---

## Part 1: Threat Modeling

**Approach.** We modeled CrowdSec as three DFDs that together cover all of our prioritized scenarios from the Security Requirements and Assurance Case assignments. Each was drawn and analyzed in the Microsoft Threat Modeling Tool using the *SDL TM Knowledge Base (Core)* template. Shared conventions (element names, trust boundaries, triage format) are in [`CONVENTIONS.md`](CONVENTIONS.md).

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
| UC-1 — Ingest & Analyze Logs | MC-1.1, MC-1.2, MC-1.3 / C1 | DFD-1 | Log Files → Security Engine (Agent) → LAPI → CrowdSec DB |
| UC-2 — Inspect HTTP Request (AppSec / WAF) | MC-2.1, MC-2.2, MC-2.3 / C2 | DFD-2 | Protected Services ↔ Remote Bouncer (enforcement decisions) |
| UC-3 — Retrieve & Enforce Decisions | MC-3.1, MC-3.2 / C3 | DFD-2 | Remote Bouncer → LAPI (X-Api-Key); LAPI → Remote Bouncer (decisions); Remote Bouncer → Protected Services |
| UC-3 — Retrieve & Enforce Decisions | MC-3.3, MC-3.4 / C3 | DFD-1 | Security Engine (Agent) → LAPI (Machine login, Alerts) |
| UC-4 — Manage Policy & Detection Content | MC-4.2, MC-4.3 / C4 | DFD-2 | cscli → LAPI (administrative API requests); Config and Credentials → LAPI |
| UC-4 — Manage Policy & Detection Content | MC-4.1 / C4 | DFD-3 | Crowdsec CLI ↔ Crowdsec Hub (Request config, Download parsers and scenarios) |
| UC-5 — Exchange Threat Intelligence | MC-5.1, MC-5.2, MC-5.3, MC-5.4 / C5 | DFD-3 | LAPI → CAPI (Send offender IPs); CAPI → LAPI (Transfer community blocklist); LAPI → Online console (Enrollment and Telemetry) |

### DFD-1: Detection pipeline
*Owner: Kowshik Chowdhury*

![DFD-1](images/dfd1-detection.png)

**Full TMT report:** [View HTML report](https://htmlpreview.github.io/?https://github.com/HapticLazier2/CSCI-8420-Group-2/blob/main/threat-modeling/reports/dfd1.htm) · [Model file](dfd1-detection/dfd1-detection.tm7)

**Scope.** DFD-1 models the CrowdSec detection pipeline from local log and configuration/credential files through the `Security Engine (Agent)` to `LAPI` and the `CrowdSec DB`. It covers log acquisition, parser/scenario processing, Agent-to-LAPI machine authentication and alert submission, and LAPI database reads and writes. The main trust changes are the `Remote Host Boundary` between the Agent and LAPI and the `LAPI Host Boundary` protecting LAPI and its database. This DFD primarily supports UC-1 (Ingest & Analyze Logs), including MC-1.1 through MC-1.3 and SR-1.1 through SR-1.5, and supports assurance claim C1 on log-ingestion resilience, source authentication, and source-attribution integrity.

**Triage summary**

| STRIDE | Generated | Mitigated | Not Applicable | Needs Investigation |
|---|---:|---:|---:|---:|
| Spoofing | 6 | 0 | 0 | 6 |
| Tampering | 5 | 0 | 0 | 5 |
| Repudiation | 2 | 0 | 0 | 2 |
| Information Disclosure | 5 | 0 | 0 | 5 |
| Denial of Service | 5 | 0 | 0 | 5 |
| Elevation of Privilege | 8 | 0 | 4 | 4 |
| **Total** | **31** | **0** | **4** | **27** |

**Mitigations for relevant threats**

| ID | Threat (STRIDE) | Element / flow | [XB] | Mitigation | Layer | Quick win / structural | Part 2 ref |
|---|---|---|---|---|---|---|---|
| D1-01 | Spoofing / Information Disclosure | Log Files | No | Restrict log-file ownership and permissions so only authorized services and administrators can read or modify acquisition inputs. | deployment/config | Quick win | D1-17 |
| D1-02 | Tampering | Log lines (file read) | No | Validate and safely parse log input; reject malformed or unexpected records and test parsers with crafted input. | code/config | Structural | D1-18 |
| D1-03 | Spoofing / Information Disclosure | Config & Credentials | No | Protect configuration and machine credential files with restrictive ownership, permissions, and least-privilege access. | deployment/config | Quick win | D1-03 |
| D1-04 | Spoofing | Machine login (HTTP/S POST) | Yes | Require authenticated and validated Agent machines before LAPI accepts machine-originated requests. | code/config | Quick win | D1-04 |
| D1-05 | Tampering / Information Disclosure / Spoofing | Machine login + Alerts (HTTP/S POST) | Yes | Protect Agent-to-LAPI traffic with TLS and server certificate verification; use mTLS where the deployment requires stronger mutual authentication. | config/deployment | Quick win | D1-05 |
| D1-06 | Tampering / Elevation of Privilege | Machine login + Alerts (HTTP/S POST) | Yes | Validate API structures, field values, sizes, and authentication data before processing; use safe parsing and reject malformed requests. | code | Structural | D1-07 |
| D1-07 | Denial of Service | Machine login + Alerts (HTTP/S POST) | Yes | Apply request/body-size limits, timeouts, exposure restrictions, monitoring, and resource controls to reduce login or alert flooding. | code/config/deployment | Structural | D1-07, D1-08 |
| D1-08 | Repudiation | Machine login + Alerts (HTTP/S POST) | Yes | Record authenticated machine identity, timestamp, request type, and processing result in audit-capable logs. | code/process | Structural | D1-10, D1-12 |
| D1-09 | Elevation of Privilege | LAPI | Yes | Run LAPI with least privilege, keep dependencies patched, and use safe request-processing practices to reduce code-execution impact. | code/deployment | Structural | Gaps: engine runs as root |
| D1-10 | Spoofing / Information Disclosure | CrowdSec DB | No | Protect database location, ownership, permissions, and connection configuration so only LAPI and authorized administrators can access or replace it. | deployment/config | Quick win | D1-13, D1-14 |
| D1-11 | Denial of Service | CrowdSec DB / LAPI | No | Use monitoring, retention controls, capacity planning, and resource limits to prevent database growth or workload from exhausting resources. | config/deployment | Structural | D1-15 |

### DFD-2: Remediation path and authentication
*Owner: Mujib Latifi*

![DFD-2](images/dfd2.PNG)

**Full TMT report:** [View HTML report](https://htmlpreview.github.io/?https://github.com/HapticLazier2/CSCI-8420-Group-2/blob/main/threat-modeling/reports/dfd2.htm) · [Model file](dfd2-remediation/dfd2-remediation.tm7)

**Scope**

The data flow diagram **2**  DFD-2 models the CrowdSec remediation path and authentication mechanisms. The model covers administrative API requests, configuration and credentials, and enforcement, read, and write decisions.

The threat model DFD-2 and its following assessments examine interactions between CrowdSec components and their data flow. The components that are covered by the model are cscli, the Local API (LAPI), remote bouncers, protected services, as well as the CrowdSec SQL database. The model DFD-2 focuses on authentication, authorization, privilege escalation, data integrity, service availability, and protection of the components against unauthorized administrative operations.

Internet boundary, LAPI host boundary, remote host boundary, and privilege boundary are the boundaries that the DFD-2 model considers to model and assess threats. The model reviews the links and communication flows across the boundaries mentioned that require authentication, authorization, input validation, and secure communication controls.

**Triage summary**

| STRIDE | Generated | Mitigated | Not Applicable | Needs Investigation |
|---|---:|---:|---:|---:|
| Spoofing | 8 | 0 | 0 | 8 |
| Tampering | 7 | 0 | 0 | 7 |
| Repudiation | 6 | 0 | 0 | 6 |
| Information Disclosure | 1 | 0 | 0 | 1 |
| Denial of Service | 16 | 0 | 0 | 16 |
| Elevation of Privilege | 9 | 0 | 0 | 9 |
| **Total** | **47** | **0** | **0** | **47** |

**Mitigations for relevant threats**

| ID | Threat (STRIDE) | Element / flow | XB? | Mitigation | Layer | Quick win / structural |
|---|---|---|---|---|---|---|
| D2-01 | Elevation Using Impersonation (EoP) | LAPI / cscli — Administrative API Requests | No | Enforce distinct service identities and least-privilege authorization. Validate the caller identity and permissions for every administrative operation. | Application / Authorization | Quick win: Review service permissions. Structural: Implement service-level identity and authorization policies. |
| D2-02 | cscli Process Memory Tampered (Tampering) | cscli / LAPI — Administrative API Requests | No | Avoid shared-memory access and unsafe pointer passing. Exchange validated data structures instead of executable references. | Application / Process Isolation | Quick win: Review memory-sharing and pointer interfaces. Structural: Use isolated processes and validated message-based communication. |
| D2-03 | Elevation Using Impersonation (EoP) | Admin / cscli — Administrative API Requests | Yes | Authenticate administrators and enforce role-based authorization for administrative commands. | Identity / Application | Quick win: Review administrator permissions. Structural: Enforce centralized authentication, authorization, and privileged-access management. |
| D2-04 | Elevation by Changing the Execution Flow in cscli (EoP) | Admin → cscli — Administrative API Requests | Yes | Validate and constrain all command arguments and API inputs. Prevent untrusted input from controlling execution paths. | Application | Quick win: Validate inputs and reject unexpected values. Structural: Use secure input handling and code-level controls against injection and execution-flow manipulation. |
| D2-05 | cscli Remote Code Execution (EoP) | Admin → cscli — Administrative API Requests | Yes | Prevent remote execution through administrative interfaces. Restrict executable operations and validate all incoming requests. | Application / Host | Quick win: Review exposed administrative operations. Structural: Separate administrative control functions from general API access and enforce least privilege. |
| D2-06 | Administrative API Requests Flow Interrupted (DoS) | Admin ↔ cscli — Administrative API Requests | Yes | Apply request timeouts, rate limits, availability monitoring, and controlled retry behavior. | Network / Application | Quick win: Configure timeouts and rate limits. Structural: Implement resilient API access and availability protections. |
| D2-07 | Potential Process Crash or Stop for cscli (DoS) | cscli — Process | No | Handle exceptions, validate inputs, and monitor process health. Define restart and recovery procedures. | Application / Host | Quick win: Enable process monitoring and restart policies. Structural: Add fault handling, health checks, and resilience testing. |
| D2-08 | Potential Data Repudiation by cscli (Repudiation) | cscli — Administrative API Requests | Yes | Log administrative requests with authenticated identity, timestamp, action, outcome, and relevant request metadata. Protect logs against alteration. | Application / Logging | Quick win: Enable audit logging. Structural: Centralize tamper-resistant audit records and retention controls. |
| D2-09 | Excessive Resource Consumption for cscli or CrowdSec Database (DoS) | cscli / CrowdSec Database — Administrative API Requests | No | Apply resource limits, query timeouts, connection limits, and request throttling. | Application / Database / Host | Quick win: Set query and request timeouts. Structural: Establish resource quotas, workload limits, and database capacity monitoring. |
| D2-10 | SQL Injection Vulnerability (Tampering) | CrowdSec Database — Administrative API Requests | No | Use parameterized queries, safe database APIs, and strict input validation. Review all dynamically constructed SQL. | Application / Database | Quick win: Review SQL construction and parameterization. Structural: Adopt secure database-access patterns and automated injection testing. |
| D2-11 | Spoofing of Destination Data Store (Spoofing) | CrowdSec Database — Administrative API Requests | No | Authenticate the database endpoint and verify its identity. Protect database connection configuration and credentials. | Database / Network | Quick win: Verify database connection settings. Structural: Enforce authenticated database connections and secure secret management. |
| D2-12 | Elevation by Changing the Execution Flow in Remote Bouncer (EoP) | LAPI → Remote Bouncer — bouncer registration | Yes | Validate registration data and prevent untrusted input from controlling bouncer execution. | Application | Quick win: Validate registration inputs. Structural: Use secure protocol handling, input schemas, and execution isolation. |
| D2-13 | Remote Bouncer Remote Code Execution (EoP) | LAPI → Remote Bouncer — bouncer registration | Yes | Restrict registration operations to authenticated and authorized requests. Prevent registration data from being interpreted as executable instructions. | Application / Host | Quick win: Review registration handlers. Structural: Enforce least privilege, secure parsing, and process isolation. |
| D2-14 | Elevation Using Impersonation (EoP) | Remote Bouncer / LAPI — bouncer registration | Yes | Authenticate the remote bouncer independently and prevent it from assuming LAPI identity or privileges. | Identity / Application | Quick win: Verify bouncer authentication. Structural: Use mutual authentication and separate service identities and permissions. |
| D2-15 | bouncer registration Flow Interrupted (DoS) | LAPI ↔ Remote Bouncer — bouncer registration | Yes | Apply connection timeouts, retry limits, rate limiting, and availability monitoring. | Network / Application | Quick win: Configure timeouts and retry limits. Structural: Implement resilient registration and service availability controls. |
| D2-16 | Potential Process Crash or Stop for Remote Bouncer (DoS) | Remote Bouncer — bouncer registration | Yes | Monitor bouncer health, handle malformed requests safely, and implement controlled recovery. | Application / Host | Quick win: Enable health monitoring and restart policies. Structural: Add fault isolation and resilience testing. |
| D2-17 | Potential Data Repudiation by Remote Bouncer (Repudiation) | Remote Bouncer — bouncer registration | Yes | Record registration requests, authenticated bouncer identity, timestamps, and registration outcomes in protected audit logs. | Application / Logging | Quick win: Log registration events. Structural: Centralize tamper-resistant audit logging. |
| D2-18 | Spoofing the LAPI Process (Spoofing) | LAPI / Remote Bouncer — bouncer registration | Yes | Authenticate LAPI to the remote bouncer and validate the identity of the connecting endpoint. | Identity / Network | Quick win: Verify endpoint identity. Structural: Enforce mutual TLS or equivalent authenticated service-to-service communication. |
| D2-19 | HTTPS Data Flow Interrupted (DoS) | config and credentials → LAPI — HTTPS | Yes | Configure connection timeouts, availability monitoring, and secure retry behavior. Protect the service from connection exhaustion. | Network / Application | Quick win: Set connection timeouts. Structural: Implement resilient communication and network-level availability controls. |
| D2-20 | Potential Process Crash or Stop for LAPI (DoS) | LAPI — config and credentials interaction | Yes | Monitor LAPI health, validate configuration inputs, and implement controlled restart and recovery procedures. | Application / Host | Quick win: Enable health checks and restart policies. Structural: Implement fault handling and high-availability design where required. |
| D2-21 | Weak Access Control for a Resource (Information Disclosure) | config and credentials — File | Yes | Restrict file and directory permissions. Limit access to authorized service accounts and administrators. Protect credentials at rest. | Host / File System / Identity | Quick win: Review file permissions. Structural: Use least-privilege access, secret management, and credential rotation. |
| D2-22 | Potential Data Repudiation by LAPI (Repudiation) | LAPI — config and credentials interaction | Yes | Record incoming requests and relevant source identity, timestamps, and processing outcomes. Protect audit records from modification. | Application / Logging | Quick win: Enable request audit logging. Structural: Centralize tamper-resistant logs with defined retention. |
| D2-23 | Spoofing of Source Data Store (Spoofing) | Configuration and Credentials — File → LAPI | Yes | Protect configuration-file integrity and verify the source and ownership of configuration data. | Host / File Integrity | Quick win: Restrict write permissions. Structural: Implement file-integrity monitoring and controlled configuration management. |
| D2-24 | Data Store Inaccessible (DoS) | config and credentials — File → LAPI | Yes | Ensure required configuration and credential files are available and protected against unauthorized deletion or modification. | Host / File System | Quick win: Monitor file availability and permissions. Structural: Implement protected configuration storage, backup, and recovery. |
| D2-25 | Elevation by Changing the Execution Flow in LAPI (EoP) | config and credentials → LAPI | Yes | Validate configuration values and prevent untrusted configuration data from changing execution behavior. | Application | Quick win: Validate configuration inputs. Structural: Use strict configuration schemas, secure parsing, and controlled configuration deployment. |
| D2-26 | LAPI Remote Code Execution (EoP) | config and credentials → LAPI | Yes | Ensure configuration and credential data cannot be interpreted as executable content. Restrict LAPI privileges and validate all configuration inputs. | Application / Host | Quick win: Review configuration parsing and execution paths. Structural: Apply least privilege, secure parsing, and process isolation. |
| D2-27 | Potential Process Crash or Stop for Remote Bouncer (DoS) | Remote Bouncer — enforcement decisions | Yes | Handle invalid or unexpected enforcement data safely. Monitor process health and implement controlled recovery. | Application / Host | Quick win: Enable bouncer health monitoring. Structural: Add fault isolation and resilience testing. |
| D2-28 | Potential Data Repudiation by Remote Bouncer (Repudiation) | Remote Bouncer — enforcement decisions | Yes | Log enforcement-decision receipt, source identity, timestamps, and processing outcomes. Protect logs from alteration. | Application / Logging | Quick win: Log enforcement events. Structural: Centralize tamper-resistant audit records. |
| D2-29 | Spoofing the Protected Services External Entity (Spoofing) | Protected Services → Remote Bouncer — enforcement decisions | Yes | Authenticate the protected service or its communication endpoint. Do not rely solely on network location to establish identity. | Identity / Network | Quick win: Verify source identity. Structural: Enforce authenticated service communication and endpoint authorization. |
| D2-30 | enforcement decisions Flow Interrupted (DoS) | Protected Services → Remote Bouncer — enforcement decisions | Yes | Apply communication timeouts, availability monitoring, and controlled retry behavior. | Network / Application | Quick win: Configure timeouts and monitoring. Structural: Design resilient enforcement communication and recovery. |
| D2-31 | Elevation by Changing the Execution Flow in Remote Bouncer (EoP) | Protected Services → Remote Bouncer — enforcement decisions | Yes | Validate enforcement data and prevent incoming values from controlling execution flow. | Application | Quick win: Validate enforcement inputs. Structural: Use strict message schemas, secure parsing, and execution isolation. |
| D2-32 | Remote Bouncer Remote Code Execution (EoP) | Protected Services → Remote Bouncer — enforcement decisions | Yes | Ensure enforcement data cannot trigger command or code execution. Restrict the bouncer process privileges. | Application / Host | Quick win: Review enforcement handlers. Structural: Enforce least privilege, secure parsing, and process isolation. |
| D2-33 | Elevation Using Impersonation (EoP) | Remote Bouncer / Protected Services — enforcement decisions | Yes | Separate the identities and permissions of the bouncer and protected services. Enforce authorization for each operation. | Identity / Application | Quick win: Review service permissions. Structural: Implement independent service identities and least-privilege authorization. |
| D2-34 | Excessive Resource Consumption for LAPI or CrowdSec Database (DoS) | LAPI / CrowdSec Database — read decisions | No | Apply request limits, database query timeouts, connection limits, and resource quotas. | Application / Database / Host | Quick win: Set query and request timeouts. Structural: Establish resource quotas, workload limits, and database capacity monitoring. |
| D2-35 | SQL Injection Vulnerability (Tampering) | CrowdSec Database — read decisions | No | Use parameterized queries and safe database APIs. Review all dynamically constructed SQL and validate inputs. | Application / Database | Quick win: Review SQL query construction. Structural: Adopt secure database-access patterns and automated injection testing. |
| D2-36 | Spoofing of Destination Data Store (Spoofing) | CrowdSec Database — read decisions | No | Authenticate the database endpoint and verify its identity. Protect database connection configuration and credentials. | Database / Network | Quick win: Verify database connection settings. Structural: Enforce authenticated database connections and secure secret management. |
| D2-37 | Excessive Resource Consumption for LAPI or CrowdSec Database (DoS) | LAPI / CrowdSec Database — write decisions | No | Apply request limits, database query timeouts, connection limits, and resource quotas. | Application / Database / Host | Quick win: Set query and request timeouts. Structural: Establish resource quotas, workload limits, and database capacity monitoring. |
| D2-38 | SQL Injection Vulnerability (Tampering) | CrowdSec Database — write decisions | No | Use parameterized queries and safe database APIs. Review all dynamically constructed SQL and validate inputs. | Application / Database | Quick win: Review SQL query construction. Structural: Adopt secure database-access patterns and automated injection testing. |
| D2-39 | Spoofing of Destination Data Store (Spoofing) | CrowdSec Database — write decisions | No | Authenticate the database endpoint and verify its identity. Protect database connection configuration and credentials. | Database / Network | Quick win: Verify database connection settings. Structural: Enforce authenticated database connections and secure secret management. |
| D2-40 | Elevation by Changing the Execution Flow in LAPI (EoP) | Remote Bouncer → LAPI — X-Api-Key | Yes | Validate and constrain API-key requests. Prevent request data from controlling LAPI execution paths. | Application / API | Quick win: Validate request fields and headers. Structural: Apply secure API design, input validation, and authorization controls. |
| D2-41 | LAPI Remote Code Execution (EoP) | Remote Bouncer → LAPI — X-Api-Key | Yes | Prevent API-key requests from triggering code or command execution. Restrict LAPI privileges and validate all request data. | Application / Host | Quick win: Review API request handlers. Structural: Enforce least privilege, secure parsing, and process isolation. |
| D2-42 | Elevation Using Impersonation (EoP) | LAPI / Remote Bouncer — X-Api-Key | Yes | Ensure LAPI cannot assume remote-bouncer identity or privileges. Enforce separate identities and authorization boundaries. | Identity / Application | Quick win: Review service identity handling. Structural: Implement mutual authentication and least-privilege service authorization. |
| D2-43 | X-Api-Key Data Flow Interrupted (DoS) | Remote Bouncer ↔ LAPI — X-Api-Key | Yes | Apply connection timeouts, rate limits, availability monitoring, and controlled retry behavior. | Network / API | Quick win: Configure timeouts and rate limits. Structural: Implement resilient API communication and availability protections. |
| D2-44 | Potential Process Crash or Stop for LAPI (DoS) | LAPI — X-Api-Key | Yes | Validate API requests, handle exceptions safely, and monitor LAPI health. Implement controlled recovery. | Application / Host | Quick win: Enable health monitoring and restart policies. Structural: Add fault handling and resilience testing. |
| D2-45 | Potential Data Repudiation by LAPI (Repudiation) | LAPI — X-Api-Key | Yes | Log API-key request receipt, authenticated bouncer identity, timestamps, and processing outcomes. Protect audit records from alteration. | Application / Logging | Quick win: Enable API audit logging. Structural: Centralize tamper-resistant audit records and retention controls. |
| D2-46 | Remote Bouncer Process Memory Tampered (Tampering) | Remote Bouncer / LAPI — X-Api-Key | Yes | Avoid shared-memory access and unsafe pointer passing. Exchange validated data structures and isolate the bouncer process. | Application / Process Isolation | Quick win: Review memory-sharing and pointer interfaces. Structural: Use process isolation and validated message-based communication. |
| D2-47 | Spoofing the Remote Bouncer Process (Spoofing) | Remote Bouncer → LAPI — X-Api-Key | Yes | Authenticate the remote bouncer and validate its identity before accepting API-key requests. Protect credentials against theft and reuse. | Identity / API | Quick win: Verify bouncer credentials and identity. Structural: Use mutual authentication, secure secret storage, and credential rotation. |

## Deduplication and similarity notes

The following entries have similar threat templates and could possibly be assumed as duplicates. However, their interaction contexts differ from each other and should remain independently traceable:

| Threat records | Why they remain separate |
|---|---|
| D2-09, D2-34, D2-37 | Resource-consumption threats occur on administrative API requests, reading decisions, and writing decisions. |
| D2-10, D2-35, D2-38 | SQL injection threats are associated with three different database interactions. |
| D2-11, D2-36, D2-39 | Database destination-spoofing threats are associated with three different database interactions. |
| D2-12 and D2-31 | Remote-bouncer execution-flow threats occur on registration and enforcement-decision interactions. |
| D2-13 and D2-32 | Remote-bouncer RCE threats have different interaction sources: LAPI and Protected Services. |
| D2-16 and D2-27 | Remote-bouncer availability threats occur on registration and enforcement-decision interactions. |
| D2-17 and D2-28 | Remote-bouncer repudiation threats occur on registration and enforcement-decision interactions. |

## Important assessment limitations

1. The report marks all 47 threats as Not Started. None of the recommended mitigations above should be interpreted as implemented or verified.
2. The report supplies generated threat descriptions, not evidence that each vulnerability exists.
3. The XB classifications are based on the supplied diagram structure and interaction names. They should be checked against the original diagram before being treated as final.
4. The report does not provide implementation evidence, test results, owners, or mitigation validation.
5. Priority is High for all 47 entries in the source report. No independent risk reassessment has been performed.

### DFD-3: External and cloud services
*Owner: Trung Phan*

![DFD-3](/threat-modeling/dfd3-external/dfd3-external-cloud.png)

**Full TMT report:** [View HTML report](https://htmlpreview.github.io/?https://github.com/HapticLazier2/CSCI-8420-Group-2/blob/main/threat-modeling/reports/dfd3.htm) · [Model file](dfd3-external/dfd3-external-cloud.tm7)

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

### AI analysis vs TMT
We (Team) ran the instructor's STRIDE-per-interaction prompt on an image of each final DFD. The raw outputs are in [`ai/`](ai/).

| DFD | Found by both | TMT only | AI only | AI noise / incorrect |
|---|---|---|---|---|
| DFD-1 | 16 | 15 | 5 | 0 |
| DFD-2 | 82 | 17 | 8 | 0 |
| DFD-3 | 18 | 9 | 9 | 0 |

The prompt only asks about interactions that cross a trust boundary, so any flow that stays inside one boundary is out of scope and counts as TMT only. That's 9 of 31 threats in DFD-1, 3 of 99 in DFD-2 and 6 of 27 in DFD-3. We left those out on purpose. The instructor's note says STRIDE-per-interaction was picked to keep the threat count manageable, and skipping those flows is how it does that.

**What each approach missed.** Where both methods looked at the same crossing, they mostly agreed. For an authenticated flow across a boundary, TMT generates eleven threat types, and the AI matched eight or nine of them. It never raised remote code execution or changing LAPI's execution flow, and in DFD-1 it also skipped cross-site request forgery. The reason was the same every time: it couldn't find a specific way in through the code. Not finding one doesn't prove the risk isn't there, though, and this is where TMT earns its place. It asks every question, whether or not anyone has an answer ready.

The AI's clearest win was the hub download flows in DFD-3. TMT gave `Request config` and `Download parsers and scenarios` two threats each, both about the flow being interrupted, because the diagram puts both ends inside the same boundary. So out of TMT's 157 threats, not one looks at how CrowdSec gets its detection rules. That's where the worst findings are. The rule index isn't signed, and the files it lists are checked against hashes stored in that same index. Supporting data files aren't checked at all. When a hash check does fail, it gets logged as "index outdated", and the packaged update script runs with `--error`, which hides the warning. Then the new rules install themselves every day without anyone reviewing them. All of this is in the current source, and a tool that only reads a diagram can't find any of it.

DFD-2 went the other way, and we think that's worth writing down. It has 99 threats across ten crossings, by far the most thorough of the three, and the AI added fairly little that TMT hadn't already raised. When a diagram is drawn tightly enough that every flow carrying a credential crosses a boundary, TMT does its job well. What the AI added there was detail rather than new ground. It pointed out that bouncer keys are static bearer tokens that can be replayed until someone deletes them, that `bouncers_autodelete` exists but does nothing unless you configure it, and that the per-bouncer records are just counters, not an audit trail.

We also learned something about the AI itself. Our first run used a prompt we wrote ourselves, and two of its threats were guesses stated just as confidently as the verified findings. We re-ran it with the instructor's prompt plus one extra rule: every mitigation has to name a real CrowdSec feature, config key or code path, or be marked GAP. After that, the guessing dropped to zero on all three diagrams. The same rule had the same effect in the misuse-case assignment. How sure the model sounds tells you nothing about whether it's right, so the fix is to make every claim point at something you can check.

**Top 10 threats by likelihood × impact**

Likelihood: 3 = anyone on the internet, no credentials needed. 2 = needs internal network access or one low-privilege credential. 1 = needs root or admin on a CrowdSec host. Impact: 1 = attacker can read data. 2 = attacker can change data or cause downtime. 3 = attacker takes control. Ties go to the threat with weaker mitigation (Absent before Partial before Present), then to internet-facing ones, then to whichever appears in more DFDs.

| Rank | ID | Threat | Likelihood | Impact | Rationale |
|---|---|---|---|---|---|
| 1 | DFD-1#12, #23; DFD-2#0, #9, #20, #31, #46, #86, #96, #107; DFD-3#1, #52 | Any approved machine can delete every ban in the system, from anywhere (elevation of privilege) | 2 | 3 | The trusted-address check exists, but only on alert deletion (`alerts.go` L348, L376), not on ban deletion (`decisions.go` L101, L134). Steal one agent's credentials and you can unban yourself and ban the admins. Nothing mitigates this, and it shows up in all three DFDs. In DFD-2 alone it appears eight times, because every enrollment flow leads to it. |
| 2 | AI only | The rule index isn't signed, and the files it lists are checked against hashes stored in that same index | 2 | 3 | Each file's SHA-256 is checked against the index (`pkg/cwhub/download.go` L103), but the index itself is never checked. Control the index or the CDN and you control every detection rule. |
| 3 | AI only | Supporting data files (pattern lists, GeoIP databases) get no integrity check at all | 2 | 3 | The download code just saves the file (`pkg/hubops/download.go` L122–149). Replace a pattern list and every rule that uses it stops working, silently. |
| 4 | DFD-1#6, #17; DFD-2#2, #13, #24, #79, #89, #100; DFD-3#45 | Spoofing LAPI | 2 | 3 | TLS is available but off by default. In a standard install, neither agents nor bouncers can tell whether they're talking to the real server. |
| 5 | DFD-1#31, #32; DFD-2#3, #14, #25, #80, #91, #101; DFD-3#2, #27 | Tampering with traffic to and from LAPI | 2 | 3 | Same cause as #4. Decisions aren't signed either, so a modified one looks exactly like a real one, and the bouncer enforces whatever it gets. |
| 6 | AI only | A failed hash check is logged as "index outdated" and then hidden | 2 | 2 | The code logs a warning and carries on (`download.go` L110). The packaged update script runs with `--error`, which only shows errors, so the warning never appears. A failed integrity check leaves no trace. |
| 7 | DFD-1#10, #21; DFD-2#7, #18, #29, #84, #94, #105; DFD-3#50 | Denial of service against LAPI | 2 | 2 | There's no rate limiting anywhere in the API server. Request size is capped, but how many requests you can send isn't. And because bouncers poll all the time, there's no normal baseline to spot a flood against. |
| 8 | DFD-1#8, #19; DFD-2#5, #16, #27, #82, #92, #103; DFD-3#48 | Repudiation: no way to prove who did what | 2 | 2 | There's no audit log. Manual bans are recorded under a shared machine account, never a person, and old records are deleted after seven days. Five separate DFD-3 mitigations assume this log exists. It doesn't. |
| 9 | AI only | New detection rules go live every day with no human review | 2 | 2 | A daily timer updates, upgrades and reloads the rules (`build/debian/hubupdate.sh`). Bad or poisoned rules reach every install by the next run. |
| 10 | AI only | An allowlist entry pushed from the cloud console hides an address from the web application firewall completely | 1 | 3 | An allowlisted IP skips every WAF check (`appsec_runner.go` L441–446). Since v1.6.9, the engine accepts these console pushes automatically if the plan allows it. The only record is one info-level log line. |

Five of these ten came from the AI, not TMT. Honestly, that's the strongest case in this report for using both.

---

## Part 2: Observations

### Mitigation review
As a team, we checked the source, docs and default config for every mitigation we expected to find. All code references are to release v1.8.1, and every path in the Evidence column links to that line on GitHub.

The DFD-3 rows take their expected control straight from that diagram's triage justifications, one per generated threat. So for DFD-3, the status column is really a check on whether the triage got it right. The DFD-1 rows match Kowshik's triaged model; the Part 2 ref column in the DFD-1 section links each planned mitigation to its row here, and D1-17 and D1-18 come from his DFD-1 review. The DFD-2 rows are our own, because that model hasn't been triaged yet.

We added the six rows numbered D3-S1 to D3-S6 ourselves. TMT didn't generate any tampering or spoofing threats for the hub download flows, so no owner ever gave those controls a mitigation ID. They come from the AI analysis and our code review.

| DFD | Mitigation ID | Expected control | Status | Evidence | Notes |
|---|---|---|---|---|---|
| DFD-1 | D1-01 | Network log inputs check who's sending | Partial | [`pkg/acquisition/modules/http/config.go#L103-L126`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/acquisition/modules/http/config.go#L103-L126), [`pkg/acquisition/modules/kubernetesaudit/config.go#L20-L24`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/acquisition/modules/kubernetesaudit/config.go#L20-L24) | The HTTP input won't start without authentication set up. The Kubernetes audit and syslog inputs have no authentication at all. |
| DFD-1 | D1-02 | Network log inputs cap request size, including after decompression | Present | [`pkg/acquisition/modules/http/config.go#L20-L21`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/acquisition/modules/http/config.go#L20-L21) | 10 MiB by default, added after GHSA-g2x2-jgfg-pg7g and GHSA-rh69-4vqj-9gj8. Timeouts are weaker: optional on HTTP, missing on Kubernetes audit. |
| DFD-1 | D1-03 | Each agent has its own login | Present | [`pkg/apiserver/middlewares/v1/jwt.go#L168`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/jwt.go#L168), [`pkg/database/machines.go#L67-L68`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/database/machines.go#L67-L68) | The server stores passwords hashed with bcrypt. The agent keeps its copy in plaintext on disk. |
| DFD-1 | D1-04 | New machines need approval before sending alerts | Present | [`pkg/apiserver/middlewares/v1/jwt.go#L164`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/jwt.go#L164) | An admin has to approve each machine first. Automatic registration needs a token and an allowed IP range. |
| DFD-1 | D1-05 | Agent-to-server traffic is encrypted | Partial | [`pkg/csconfig/api.go#L190-L193`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/api.go#L190-L193) | Certificates are verified when TLS is on, but TLS is optional and the default install uses plain HTTP. |
| DFD-1 | D1-06 | Session tokens use a strong secret and expire | Present | [`pkg/apiserver/middlewares/v1/jwt.go#L276-L286`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/jwt.go#L276-L286), [`#L297-L298`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/jwt.go#L297-L298) | The server won't start with a weak secret. Tokens last one hour. |
| DFD-1 | D1-07 | The server caps request size after decompression | Present | [`pkg/apiserver/middlewares/v1/body_limit.go#L12-L13`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/body_limit.go#L12-L13) | 2 MiB before login, 50 MiB after. Added after CVE-2026-44981. |
| DFD-1 | D1-08 | Repeated failed logins get throttled | **Absent** | [`pkg/apiserver/`](https://github.com/crowdsecurity/crowdsec/tree/v1.8.1/pkg/apiserver) | No rate limiting of any kind. We searched for the usual names and libraries and found nothing. |
| DFD-1 | D1-09 | Only trusted admin addresses can delete bans | **Absent** | [`pkg/apiserver/controllers/v1/decisions.go#L101`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/v1/decisions.go#L101), [`#L134`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/v1/decisions.go#L134) vs [`alerts.go#L348`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/v1/alerts.go#L348), [`#L376`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/v1/alerts.go#L376) | `trusted_ips` protects alert deletion but not ban deletion. Any approved machine can wipe every ban from anywhere. |
| DFD-1 | D1-10 | Every alert can be traced to the machine that sent it | Present | [`pkg/apiserver/controllers/v1/alerts.go#L186`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/v1/alerts.go#L186) | The server takes the machine name from the login token. |
| DFD-1 | D1-11 | Admin actions can be traced to a person | **Absent** | [`cmd/crowdsec-cli/clidecision/decisions.go#L156`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec-cli/clidecision/decisions.go#L156), [`#L270`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec-cli/clidecision/decisions.go#L270) | The command-line tool records the machine account, not the user. Everyone with root on the box looks the same. |
| DFD-1 | D1-12 | Security records can't be quietly changed | **Absent** | — | No audit log, and the docs don't mention one. Records sit in an ordinary database that gets pruned. |
| DFD-1 | D1-13 | Only the owner can read the database file | Partial | [`pkg/database/database.go#L83-L95`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/database/database.go#L83-L95) | Created with mode 0600, then set to 0640, so the file's group can read it too. |
| DFD-1 | D1-14 | The database is encrypted at rest | **Absent** | — | There's no option for it. |
| DFD-1 | D1-15 | The database can't grow forever | Present | — | By default it keeps 5000 alerts or seven days, whichever comes first. The catch is that this also throws away evidence (see D1-12). |
| DFD-1 | D1-16 | Bad config is caught before it's used | Present | [`config/crowdsec.service#L8-L12`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/config/crowdsec.service#L8-L12), [`pkg/csconfig/config.go#L64`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/config.go#L64) | Any config error stops startup, and the service tests the config before every start and reload. |
| DFD-1 | D1-17 | Restrict log-file ownership and permissions so only authorized services and administrators can read or modify acquisition inputs. | Partial | [CrowdSec file acquisition docs](https://docs.crowdsec.net/docs/log_processor/data_sources/file/) | CrowdSec reads host log files but the supplied project evidence does not show a CrowdSec-specific permission mechanism for arbitrary /var/log inputs; protection depends on host filesystem permissions. |
| DFD-1 | D1-18 | Validate and safely parse log input; reject malformed or unexpected records and test parsers with crafted input. | Present | [`pkg/parser/node.go#L181`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/parser/node.go#L181) | Earlier requirements review found that non-matching lines are marked unparsed and discarded before scenarios. |
| DFD-2 | D2-01 | Each bouncer gets its own credential that can be revoked on its own | Present | [`cmd/crowdsec-cli/clibouncer/add.go`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec-cli/clibouncer/add.go), [`delete.go`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec-cli/clibouncer/delete.go) | `cscli bouncers add` creates one key per bouncer, and `delete` revokes it. |
| DFD-2 | D2-02 | Bouncer keys are stored hashed, not in the clear | Present | [`pkg/apiserver/middlewares/v1/api_key.go#L79`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/api_key.go#L79) | The key is hashed with SHA-512 and looked up by hash. There's no salt, but that's fine for long random keys. |
| DFD-2 | D2-03 | Bouncers can only read decisions, never change them | Present | [`pkg/apiserver/controllers/controller.go#L132-L156`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/controller.go#L132-L156) | A bouncer key can only reach the routes that read decisions, plus the one for reporting usage metrics. This is the best least-privilege result in the whole model. |
| DFD-2 | D2-04 | Bouncer credentials expire or rotate | **Absent** | — | Keys are static bearer tokens that never expire. A stolen key keeps working until someone deletes it. |
| DFD-2 | D2-05 | Unused bouncer credentials get cleaned up | Partial | [`pkg/database/flush.go#L92-L96`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/database/flush.go#L92-L96) | `bouncers_autodelete` exists, with separate timeouts for certificate and API-key bouncers, but it does nothing unless you configure it. |
| DFD-2 | D2-06 | A bouncer certificate can't be used to act as an agent | Present | [`pkg/apiserver/middlewares/v1/tls_auth.go#L51-L65`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/tls_auth.go#L51-L65) | Each role has a list of allowed OUs, and the certificate's OU is checked against it. This only applies when TLS client auth is on. |
| DFD-2 | D2-07 | Revoked bouncer certificates are rejected | Partial | [`pkg/apiserver/middlewares/v1/tls_auth.go#L51-L65`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/tls_auth.go#L51-L65) | If no CRL is configured, the check is skipped. It's also skipped if the CRL is invalid or expired. In other words, it fails open. |
| DFD-2 | D2-08 | Bouncer-to-server traffic is encrypted | Partial | — | Same as D1-05. TLS is optional and the default install uses plain HTTP, so the decision stream (the blocklist itself) crosses the network in cleartext. |
| DFD-2 | D2-09 | Decisions can't be forged in transit | **Absent** | — | Decisions aren't signed. Without TLS, a modified decision looks exactly like a real one, and the bouncer enforces whatever it receives. |
| DFD-2 | D2-10 | LAPI records which bouncer asked for what | Partial | — | LAPI keeps each bouncer's address and the last time it pulled, which `cscli bouncers list` shows. Since v1.6.3, bouncers can also report usage metrics. These are counters, though, not a record of each request. |
| DFD-2 | D2-11 | New machines need approval before they can act | Present | [`pkg/database/machines.go#L140`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/database/machines.go#L140), [`pkg/csconfig/api.go#L546`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/api.go#L546) | New machines start out unapproved. Auto-registration needs a token, and LAPI won't start if it's turned on without `allowed_ranges`. |
| DFD-2 | D2-12 | Auto-registration is limited to known networks | Partial | — | It needs both the token and the IP ranges, and a wrong token is rejected. It's off by default, but the documented Kubernetes Helm chart setup turns it on and allows every private range. |
| DFD-2 | D2-13 | Enrollment approvals can be traced to a person | **Absent** | — | `cscli machines` writes straight to the database instead of going through the API, so nothing records who approved an enrollment. |
| DFD-2 | D2-14 | `cscli` separates read-only users from admins | **Absent** | — | `cscli` has no roles. Anyone who can run it as root is a full admin. The cloud console has roles, but that doesn't help at the command line. |
| DFD-2 | D2-15 | The enforcement point can fail closed | Partial | — | Setting `APPSEC_FAILURE_ACTION=deny` makes it fail closed, but the default lets traffic through. If the engine is down or slow, requests pass without inspection. |
| DFD-2 | D2-16 | Decision requests are rate limited | **Absent** | [`pkg/apiserver/`](https://github.com/crowdsecurity/crowdsec/tree/v1.8.1/pkg/apiserver) | No rate limiting anywhere. Bouncers poll all the time, so there's no normal baseline to spot a flood against. |
| DFD-3 | D3-01 | Require TLS cert auth before access (impersonation of cscli) | Partial | [`pkg/apiserver/middlewares/v1/tls_auth.go#L51-L65`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/tls_auth.go#L51-L65) | Mutual TLS exists and can restrict by OU, but it's off by default and revocation fails open. |
| DFD-3 | D3-02 | Enforce HTTPS for hub downloads | Present | [`pkg/csconfig/cscli.go#L21`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/cscli.go#L21) | The default source is an HTTPS CDN. |
| DFD-3 | D3-03 | Automated cron jobs with retry logic for `cscli` updates | Present | [`build/debian/hubupdate.sh`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/build/debian/hubupdate.sh) | A daily systemd timer runs update, upgrade and reload. It matches what the triage asks for, but it's the same thing the Gaps table calls a risk, because nothing reviews what it installs. |
| DFD-3 | D3-04 | Monitor and audit `cscli` execution logs | **Absent** | — | There's no audit log. `cscli` writes to the normal log and doesn't record who ran it. |
| DFD-3 | D3-05 | Queue console telemetry locally and retry when connectivity returns | Partial | [`pkg/apiserver/apic.go#L294-L325`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/apic.go#L294-L325) | Signals pile up in an in-memory cache and get flushed on shutdown. The cache isn't saved to disk, so a restart during an outage loses them. |
| DFD-3 | D3-06 | Log telemetry transmissions and enrollment handshakes locally | **Absent** | — | No audit log, just normal logging, which gets pruned with everything else. |
| DFD-3 | D3-07 | Require TLS cert auth before access (console spoofing) | Partial | — | The console connection uses HTTPS and per-install credentials, but no client certificate is required. |
| DFD-3 | D3-08 | Resilient outbound routing and retry logic for `cscli hub update` | **Absent** | [`build/debian/hubupdate.sh`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/build/debian/hubupdate.sh) | The update script has no retry. If a run fails, it just waits for the next day's timer. |
| DFD-3 | D3-09 | Detailed local logging of outbound Hub requests and response codes | **Absent** | — | Not implemented. Nothing records individual hub requests. |
| DFD-3 | D3-10 | Queue and cache offender IPs locally during outages | Partial | [`pkg/apiserver/apic.go#L294-L325`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/apic.go#L294-L325) | Same in-memory cache as D3-05, so it doesn't survive a restart. |
| DFD-3 | D3-11 | Log HTTP 200 responses after pushing signals | **Absent** | — | No audit log. Push results only show up in normal logs. |
| DFD-3 | D3-12 | Strict TLS certificate validation when pushing signals | Present | [`pkg/csconfig/api.go#L190-L193`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/api.go#L190-L193) | Certificate checking is on unless someone turns it off. |
| DFD-3 | D3-13 | Strict file system permissions on hub configs | Present | — | The packages write hub content into root-owned directories. |
| DFD-3 | D3-14 | OS-level file permissions or strong auth on the database | Present | [`pkg/database/database.go#L83`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/database/database.go#L83) | The SQLite file is created with mode 0600. |
| DFD-3 | D3-15 | Limit resource usage per connection at OS level | **Absent** | [`pkg/apiserver/`](https://github.com/crowdsecurity/crowdsec/tree/v1.8.1/pkg/apiserver) | No rate limiting or per-connection limits in the API server. The database pruning caps storage, not connections. |
| DFD-3 | D3-16 | Enforce HTTPS on the LAPI-to-database flow | Not applicable | — | This flow is a local file or socket, not a REST call. |
| DFD-3 | D3-17 | Reject browser session cookies; rely on API keys for machine traffic | Not applicable | — | LAPI is a machine-to-machine API and never issues browser sessions, so this threat doesn't apply. |
| DFD-3 | D3-18 | Input validation plus OS-level exploit mitigations | Partial | [`pkg/apiserver/middlewares/v1/body_limit.go#L12-L13`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/body_limit.go#L12-L13) | Request bodies have a size cap and API input is checked against a schema. There's no hardening beyond what the OS already gives you. |
| DFD-3 | D3-19 | Keep software updated and run with least privilege | Partial | — | Dependabot handles dependency updates, but the engine runs as root in the packaged install. |
| DFD-3 | D3-20 | Validate TLS certificates and check payload signatures | Partial | [`pkg/apiclient/`](https://github.com/crowdsecurity/crowdsec/tree/v1.8.1/pkg/apiclient) | Certificate checking is there. Payload signing isn't: nothing signs blocklist or console content beyond the TLS session. |
| DFD-3 | D3-21 | Cache the most recent blocklist locally so enforcement survives outages | Present | [`pkg/apiserver/apic.go#L636-L639`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/apic.go#L636-L639) | Pulled decisions are saved to the database and stay there until they expire. |
| DFD-3 | D3-22 | Run LAPI under a process manager with automatic restart | Present | [`config/crowdsec.service#L13-L14`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/config/crowdsec.service#L13-L14) | `Restart=always` with `RestartSec=60`, so detection is down for at least a minute after a crash. |
| DFD-3 | D3-23 | Enforce HTTPS for REST API communications (sniffing) | Present | [`cmd/crowdsec-cli/clicapi/capi.go#L27`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec-cli/clicapi/capi.go#L27) | The CAPI connection is HTTPS with a hard-coded URL. The LAPI side is covered by D1-05 and is weaker. |
| DFD-3 | D3-24 | Audit logging of received community blocklists | **Absent** | — | No audit log exists. The triage proposes one, but the product doesn't have it. |
| DFD-3 | D3-25 | Input validation and sanitisation of blocklist payloads | Partial | [`pkg/database/alerts.go#L384`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/database/alerts.go#L384) | Addresses and durations are checked for valid format, and bad entries are skipped. Nothing checks whether the content is authentic. |
| DFD-3 | D3-26 | Strict TLS certificate validation when pulling blocklists | Present | [`pkg/csconfig/api.go#L190-L193`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/api.go#L190-L193) | Same control as D3-12. |
| DFD-3 | D3-27 | Strong, unique API keys for LAPI-to-CAPI authentication | Present | [`cmd/crowdsec-cli/clicapi/capi.go#L27`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec-cli/clicapi/capi.go#L27) | Each install has its own credentials in `online_api_credentials.yaml`. |
| DFD-3 | D3-S1 | The rule index is verified before use | **Absent** | [`pkg/cwhub/download.go`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/cwhub/download.go) | Nothing checks it. With no signature, all the trust sits on the TLS connection to the CDN. |
| DFD-3 | D3-S2 | Downloaded rules are integrity-checked | Partial | [`pkg/cwhub/download.go#L103`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/cwhub/download.go#L103) | They're checked against hashes from the unverified index, so a tampered index passes. |
| DFD-3 | D3-S3 | A failed integrity check stops the install and gets reported | **Absent** | [`pkg/cwhub/download.go#L110`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/cwhub/download.go#L110), [`build/debian/hubupdate.sh`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/build/debian/hubupdate.sh) | It's logged as a warning ("index outdated") and the install carries on. The update script hides warnings anyway. |
| DFD-3 | D3-S4 | Data files are integrity-checked | **Absent** | [`pkg/hubops/download.go#L122-L149`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/hubops/download.go#L122-L149) | Pattern lists and GeoIP databases are never hash-checked. |
| DFD-3 | D3-S5 | Rule updates are reviewed before going live | **Absent** | [`build/debian/hubupdate.sh`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/build/debian/hubupdate.sh) | A daily timer updates and reloads everything, with no review step. |
| DFD-3 | D3-S6 | Blocklists and console pushes are signed | **Absent** | [`pkg/apiclient/`](https://github.com/crowdsecurity/crowdsec/tree/v1.8.1/pkg/apiclient), `pkg/apiserver/papi*` | We searched for any signing or signature check and found none. Only TLS protects them. |

**Summary:** Out of 67 expected mitigations, 24 are present, 19 are partial, 22 are missing and 2 don't apply.

The DFD-3 numbers deserve their own line. Its triage marks all 27 generated threats as "Mitigation Implemented". When we checked those same 27 against the source, we got 10 present, 8 partial, 7 absent and 2 not applicable.

### Gaps

The main thing this review shows is that a missing control and a control that's just switched off are different problems, and they need different fixes.

| Gap | Threat left open | Default config or missing in code? | Impact | Recommendation |
|---|---|---|---|---|
| Ban deletion ignores `trusted_ips` | DFD-1#12, #23; DFD-2#0, #9, #20, #31, #46, #86, #96, #107; DFD-3#1, #52 (elevation of privilege) | Missing in code | Any approved machine can wipe every ban from anywhere, including the ones protecting the admins. Every enrollment flow in DFD-2 ends up here | Reuse the address check that alert deletion already has |
| No rate limiting on the API | DFD-1#10, #21, #28; DFD-2#7, #18, #29, #66, #75, #84, #94, #105; DFD-3#26, #50 (denial of service) | Missing in code | Unlimited password guessing and request floods. Bouncers poll all the time, so there's no normal baseline to tell an attack from regular traffic | At least throttle the login and enrollment endpoints |
| No audit log of admin actions | DFD-1#8, #19; DFD-2#5, #16, #27, #82, #92, #103; DFD-3#38, #40, #43, #48, #59 (repudiation) | Missing in code | Deletions, enrollments and config changes leave no trace, and whatever records exist are gone after seven days. Five separate DFD-3 mitigations assume this log exists. The per-bouncer records are counters and a last-pull time, not a record of each request | Log who made each change, in an append-only log |
| TLS is off by default | DFD-1#6, #17, #31, #32; DFD-2#2, #13, #24, #79, #89, #100; DFD-3#2, #27, #45 (spoofing and tampering) | Default config | In a multi-host setup, both credentials and the decision stream cross the network in cleartext | Make TLS the default for anything beyond a single machine |
| Certificate revocation fails open | DFD-1#6; DFD-2#2 (spoofing) | Default config | A revoked certificate still works if no CRL is set, or if the CRL is invalid or expired | Fail closed when revocation can't be checked, or require a CRL with mTLS |
| Decisions aren't signed | DFD-2#41 on the decision stream, plus #3, #14, #25, #80, #91, #101 (tampering) | Missing in code | A modified decision looks exactly like a real one, and the bouncer enforces whatever arrives. Blocklists pulled from CAPI have the same problem | Sign decisions when they're created and verify them at the bouncer |
| Bouncer keys never expire | DFD-2#23, #40, #78 (spoofing) | Missing in code | A stolen key works until someone notices and deletes it. `bouncers_autodelete` only removes idle bouncers, and only if it's configured | Use short-lived tokens, or at least turn on `bouncers_autodelete` |
| The rule index isn't signed | Not found by TMT | Missing in code | Control the index or the CDN and you control every rule in the deployment | Sign the index and check it against a pinned key |
| Data files are never hash-checked | Not found by TMT | Missing in code | A swapped pattern list or GeoIP file quietly turns off detection | Put their hashes in the index and check them on download |
| Integrity failures show up as harmless warnings | Not found by TMT | Missing in code, made worse by default config | A hash mismatch raises no error, and the update script hides the warning | Fail with an error on mismatch, and stop hiding warnings in the update script |
| Rules update daily with no review | DFD-3 mitigation D3-03, where it is listed as a mitigation | Default config | Bad or poisoned rules reach every install within 24 hours. DFD-3's triage lists automatic updates as a denial-of-service fix, which buys availability at the cost of integrity | Keep the timer for availability, but require approval and a trial period in simulation mode before upgrades go live |
| AppSec fails open by default | DFD-2#44 (denial of service) | Default config | If the AppSec engine is down or slow, traffic goes through uninspected | Set `APPSEC_FAILURE_ACTION=deny` on purpose instead of inheriting the default |
| Signal queues live in memory only | DFD-3#44, #60 (denial of service) | Missing in code | Signals cached during an outage are lost if the process restarts before the connection comes back | Save the outbound cache to disk |
| Two log inputs have no authentication | Not in DFD-1 | Missing in code | Anyone who can reach the syslog or Kubernetes audit port can inject fake logs that trigger bans | Add authentication to both, like the HTTP input has |
| The database isn't encrypted at rest | DFD-1#2, #4, #30; DFD-2#35 (information disclosure) | Missing in code | There's no option for it. Anyone who reaches the file — a backup, a stolen disk, another root process — reads every alert, ban and machine credential. File permissions are the only thing protecting it | Support an encrypted datastore, or document putting it on an encrypted volume and keep the 0600 permissions |
| `cscli` has no roles | DFD-2#0, #1 (elevation of privilege and spoofing) | Missing in code | Anyone who can run `cscli` as root is a full administrator. There's no read-only operator, so routine checks need the same access as deleting every ban. The cloud console has roles, which doesn't help at the command line | Separate read-only commands from administrative ones, or restrict the administrative ones through sudo rules |
| Auto-registration can be opened to every private range | DFD-2#12, #23 (spoofing) | Default config | It's off by default and needs a token, but the documented Kubernetes Helm setup turns it on and allows all private ranges. Any pod in the cluster can then enrol as a machine | Narrow `allowed_ranges` to the subnet the agents actually run in |
| The engine runs as root | DFD-3#53, #54; DFD-1#13, #14 (elevation of privilege) | Default config | The packaged install runs as root, so any code-execution bug in the engine is immediately root on the host | Run under a dedicated user and grant only the capabilities the acquisition modules need |
| No hardening beyond OS defaults | DFD-3#47; DFD-1#7, #18 (tampering) | Missing in code | Request bodies are size-capped and API input is schema-checked, but nothing ships a seccomp or AppArmor profile, so an exploited parser has the whole system call surface | Ship a hardening profile with the packages |
| `cscli hub update` has no retry | DFD-3#39, #41 (denial of service) | Missing in code | A single failed run leaves the rules a day stale and nothing says so, because the update script hides warnings | Retry with backoff, and report a failed update as an error |
| The server can't start without the cloud | Not found by TMT | Missing in code | If the cloud is down during a restart, local protection doesn't come back | Let startup continue if the cloud login fails |

### Team collaboration
Task assignments, issues and progress: **[Project board](https://github.com/HapticLazier2/CSCI-8420-Group-2/projects)** · [Issues for this assignment](https://github.com/HapticLazier2/CSCI-8420-Group-2/issues)

| Member | Responsibilities |
|---|---|
| Leonard Meredith | Lead: conventions, boundary review, report hosting, assembly, submission |
| Kowshik Chowdhury | DFD-1 detection pipeline, TMT analysis, Part 2 code review |
| Mujib Latifi | DFD-2 remediation & auth, TMT analysis, Part 2 code review |
| Trung Phan | DFD-3 external/cloud, TMT analysis, Part 2 code review |
| Hrudhay Rao Chepyala | AI STRIDE analysis & comparison, prioritization, Part 2 consolidation |

### Reflection

#### Steve Phan
What I learned:

* Practice modeling and designing the system using DFD level 1
* Threat assessing using STRIDE threat model
* Mitigate real vulnerabilities scenario from Microsoft TMT

What I found most useful

* Verifying each TMT justification against crowdsecurity/crowdsec packages (pkg/apiserver/apic.go, pkg/cwhub, config/config.yaml) turned abstract threat modeling claims into concrete, auditable engineering findings.

What I would do differently

* Inspect default configuration files (config.yaml) during Part 1 triage: I initially wrote Part 1 justifications based on CrowdSec's documented security capabilities (such as mTLS and OS resource limits). Checking config/config.yaml and crowdsec.service during Part 1 triage would have allowed me to flag "Partial / opt-in" mitigations earlier rather than discovering them during the Part 2 code review.

#### Kowshik
What I learned:
From this assignment, I learned how to use a Data Flow Diagram and STRIDE to identify security threats in a real open-source project. I also learned that finding a threat is not enough. We also need to check whether the software actually has a mitigation for the threat.

What I found most useful:
The most useful part for me was comparing the threat model with the real CrowdSec code, documentation and default configuration. This helped me understand the difference between a control that is fully present, only partially implemented or completely missing.

I also learned that trust boundaries are very important because many serious threats happen when data moves between different systems, such as between the CrowdSec Agent and LAPI. Overall, this assignment helped me understand how threat modeling can be connected with real software implementation and security gaps.

#### Hrudhay
What I learned: Where you draw the trust boundaries decides what a threat model can find. TMT produced 157 threats across our three DFDs, but none of them covered how CrowdSec downloads its detection rules. Both ends of that flow were inside the same boundary, so the tool never looked at it, and that's where our worst findings ended up being.

What I found most useful: Checking each claimed mitigation against the actual CrowdSec source instead of taking the triage at its word. More than once, a threat was marked as handled when the code showed it wasn't. That gap taught me more than anything else in this assignment.

#### Leonard
What I learned

I learned that a threat model depends heavily on how the diagram is drawn. When our DFD-2 boundaries were too broad, TMT generated 99 threats. After fixing them, it dropped to 47. I also learned that planning a mitigation is not the same as CrowdSec actually having it.

What I found most useful

Checking our mitigations against the real CrowdSec code was the most useful part. It showed which controls actually exist and which are missing. The AI analysis also helped by finding issues TMT missed, but only when its claims were tied to real code.

What I would do differently

I would review trust boundaries before anyone starts triaging, and set earlier deadlines for the reports so the final assembly isn’t rushed.
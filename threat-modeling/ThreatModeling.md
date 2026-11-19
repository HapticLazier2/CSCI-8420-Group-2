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
   - [AI analysis vs TMT](#ai-analysis-vs-tmt)
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

![DFD-3](threat-model/images/dfd3.png)

**Full TMT report:** [View HTML report](https://htmlpreview.github.io/?https://github.com/OWNER/REPO/blob/main/threat-model/reports/dfd3.htm) · [Model file](threat-model/dfd3-external/dfd3-external.tm7)

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
| D3-01 | | | | | | |

### Cross-boundary threat summary
<!-- Lead: pull every [XB] threat from the three tables. This is the section graders look for. -->

| ID | Boundary crossed | Flow | Threat | Mitigation | Priority |
|---|---|---|---|---|---|
| | | | | | |

**Design guardrails.** <!-- 2–4 controls that remove whole classes of threats, e.g. "mutual TLS required on every cross-host flow" -->

### AI analysis vs TMT
We (Team) ran the instructor's STRIDE-per-interaction prompt on an image of each final DFD. The raw outputs are in [`threat-modeling/ai/`](threat-modeling/ai/).

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

The DFD-3 rows take their expected control straight from that diagram's triage justifications, one per generated threat. So for DFD-3, the status column is really a check on whether the triage got it right. The DFD-1 and DFD-2 rows are our own, because those models haven't been triaged yet.

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
| DFD-1 | D1-13 | Only the owner can read the database file | Present | [`pkg/database/database.go#L83`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/database/database.go#L83) | Created with mode 0600. |
| DFD-1 | D1-14 | The database is encrypted at rest | **Absent** | — | There's no option for it. |
| DFD-1 | D1-15 | The database can't grow forever | Present | — | By default it keeps 5000 alerts or seven days, whichever comes first. The catch is that this also throws away evidence (see D1-12). |
| DFD-1 | D1-16 | Bad config is caught before it's used | Present | [`config/crowdsec.service#L8-L12`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/config/crowdsec.service#L8-L12), [`pkg/csconfig/config.go#L64`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/config.go#L64) | Any config error stops startup, and the service tests the config before every start and reload. |
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

**Summary:** Out of 65 expected mitigations, 24 are present, 17 are partial, 22 are missing and 2 don't apply.

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

# Requirements for Software Security Engineering
[Github Link](https://github.com/HapticLazier2/CSCI-8420-Group-2)

[ProjectBoard Link](https://github.com/users/HapticLazier2/projects/1)

CSCI-8420 Group 2 · System of interest: CrowdSec Security Engine (v1.8.x) · Environment: enterprise network (Multi-server LAPI)

## Essential Interactions with Operation Environment

The **CrowdSec System** is treated as the system-of-interest. Only interactions crossing the boundary between the CrowdSec System and an external human or enterprise system are modeled.

CrowdSec internal components such as LAPI, CAPI, agents, parsers, detection scenarios, and bouncers are treated as features/components of the **CrowdSec System**, not as external actors.

The external environment is an enterprise security environment containing systems such as Splunk, enterprise firewalls, web applications, reverse proxies, administrators/SOC personnel, and the CrowdSec community threat intelligence network.

Each interaction contains:

- An external actor/system.
- A CrowdSec feature that supports the interaction.
- A legitimate use case.
- A contextualized misuse case.
- Security requirements derived from the misuse analysis.
- Software-assurance concerns such as authentication, authorization, input validation, trust boundaries, secure failure, availability, integrity, traceability, testing, and defense in depth.

The editable source for every diagram is [`CrowdSec_Use_Misuse_Cases.drawio`](resources/static/issue3-4/CrowdSec_Use_Misuse_Cases.drawio) (one page per use case plus a page with the complete final diagram). Open it in [app.diagrams.net](https://app.diagrams.net) with *File → Open from → Device*.

| # | External actor | Use case (CrowdSec feature) |
|---|---|---|
| UC-1 | Enterprise Log Source (servers, syslog, SIEM forwarder) | Ingest & Analyze Logs — acquisition, parsers, scenarios |
| UC-2 | Web App / Reverse Proxy (AppSec-enabled bouncer) | Inspect HTTP Request — AppSec / WAF |
| UC-3 | Remediation Component (firewall or reverse-proxy bouncer) | Retrieve & Enforce Decisions — LAPI decisions API |
| UC-4 | SOC Administrator (cscli, config files) | Manage Policy & Detection Content — cscli, Hub, allowlists |
| UC-5 | CrowdSec Central API (CAPI) | Exchange Threat Intelligence — signals and community blocklist |

---

### 1. Method and notation

We used standard use/misuse case notation (Sindre & Opdahl):

- **White ellipse** = use case or security function (security use case). **Black ellipse** = misuse case.
- **White actor** = legitimate external actor. **Black actor** = misuser.
- `«include»` links a use case to a security function it depends on, `«threatens»` links a misuse case to the use case it attacks, and `«mitigates»` links a security function to the misuse case it counters.

For each use case we iterated in **rounds**. Round 1 starts from the most obvious misuse of the feature. We then added a security function that CrowdSec itself implements, asked *"once this control exists, what can an attacker still do?"*, and added the answer as the next round's misuse case. We stopped when the remaining misuse would require a control outside CrowdSec. In each diagram, rounds read top to bottom.

Following the guidance, we preferred mitigations **implemented by the OSS project**. Each security function carries a status tag:

| Tag | Meaning |
|---|---|
| **implemented** | Present in the CrowdSec engine or its official bouncers, on by default. |
| **opt-in** | Implemented, but the operator must enable it (default is weaker). |
| **fixed after advisory** | Was a gap; closed after a published GitHub Security Advisory. |
| **service-side** | Performed by CrowdSec SAS's hosted service, so not verifiable in the OSS repo. Drawn dashed. |
| **GAP** | Not implemented; required by our analysis. Drawn dashed. |

### 2. Misuser catalog

Misuser names are chosen to tell the reader the motive, the access, and the attack. Threat IDs refer to the threat list in our proposal: **T1** LAPI/agent compromise, **T2** stolen credentials/API keys, **T3** malicious logs and crafted HTTP, **T4** poisoned detection content, **T5** bouncer compromise/spoofing, **T6** dependency vulnerabilities, **T7** denial of service.

| Misuser | Motive | Resources | Access to the system | Attack of choice | Threat |
|---|---|---|---|---|---|
| **Log-Forging Outsider** | Get CrowdSec to ban a partner, admin, or payment-gateway IP (self-inflicted DoS), or hide their own IP | Scripts, knowledge of common log formats | Unauthenticated; controls text written into logs (usernames, URLs, User-Agent, X-Forwarded-For) | Log injection / source spoofing | T3 |
| **Credentialed Log-Pusher** | Crash the agent to blind detection before a real intrusion | Log-shipper credential stolen from a compromised app server | Network reach to HTTP / Kubernetes-audit acquisition endpoints | Oversized or gzip-bomb bodies (CWE-409/770) | T3, T7 |
| **Low-and-Slow Botnet Operator** | Brute-force or spray credentials without tripping detection | Botnet or residential-proxy pool with thousands of IPs | Public login endpoints only | Distributed attack kept under bucket thresholds | T3 |
| **Remote Web Exploiter** | Data theft or RCE on public web apps | Public exploit kits and scanners | Unauthenticated internet HTTP | SQLi, XSS, CVE exploit payloads | T3 |
| **WAF-Evasion Specialist** | Get a known-bad payload past the WAF | Knowledge of HTTP parser differentials; load tools | Unauthenticated internet HTTP | Alternate body framing; overloading AppSec so it fails open | T3, T7 |
| **Bouncer-Key Thief** | Learn what is blocked, check whether own IPs are banned, pose as a bouncer | Foothold on one web host | Read access to `/etc/crowdsec/bouncers/*.yaml`; network reach to LAPI | Replay of a stolen bouncer API key | T2, T5 |
| **Network-Positioned Interceptor** | Strip ban decisions so attack traffic passes; harvest keys | ARP/DNS spoofing or a compromised switch | Internal segment between bouncers and a network-exposed LAPI | Man-in-the-middle on LAPI traffic | T1, T5 |
| **Rogue-Agent Registrant** | Push fake alerts to unban themselves or ban executives/partners | Leaked auto-registration token | Host inside the network that can reach LAPI | Registering a malicious log processor | T1, T2 |
| **Pre-Auth LAPI Flooder** | Knock LAPI over so no new decisions reach bouncers | Botnet or a single fast host | Network reach to an exposed LAPI, no credentials | Gzip bombs against `/v1/watchers/login` | T1, T7 |
| **Malicious Hub Contributor** | Create false negatives for their own campaign, or false positives at scale | GitHub account, scenario-writing skill | Can open pull requests against the public Hub | Poisoned or subtly broken parser/scenario | T4 |
| **Insider SOC Analyst** | Let an accomplice through, or sabotage detection | Legitimate shell/sudo on the LAPI host | cscli and CrowdSec config files | Quiet allowlist edit; broken config | T1 |
| **Sybil Blocklist Poisoner** | Get a victim's IP blocked by every CrowdSec user | Many cheap VPS instances each running CrowdSec | Legitimate CAPI enrollment | Coordinated fake signals | T4 |
| **Upstream Traffic Interceptor** | Inject or strip community-blocklist entries | DNS hijack or rogue egress proxy | Enterprise's outbound path to CAPI | Impersonating CAPI | T4 |
| **Signal-Data Harvester** | Learn about the enterprise's internal network from shared data | Access to the central service's data (breach or insider) | Receives whatever the engine shares upstream | Mining alert context in signals | *new — found during iteration* |

T6 (dependency vulnerabilities) is not an interaction with an external actor, so it has no use/misuse case. It is handled by the project's Dependabot-managed `go.mod` noted in our proposal.

---

## 3. Use/Misuse Cases

### UC-1 — Ingest & Analyze Logs

The Enterprise Log Source feeds log lines to CrowdSec acquisition datasources. Parsers extract fields; scenarios (leaky buckets) decide whether behavior is malicious and raise alerts.

**Primary actor:** Enterprise Log Source (servers, syslog, SIEM forwarder)

**CrowdSec feature:** Acquisition datasources, parsers, scenarios (leaky buckets)

**Description:** The enterprise log source sends log lines to CrowdSec. The engine parses them into structured events (source IP, user, target) and feeds them to behavior scenarios. When a scenario's threshold is crossed, CrowdSec raises an alert that can lead to a decision.

**Preconditions:**

- The datasource is configured (file, syslog, HTTP, Kubernetes audit).
- The relevant parsers and scenarios are installed from the Hub.

**Main flow:**

1. The log source delivers log lines to an acquisition datasource.
2. Network datasources authenticate the sender and enforce size and timeout limits.
3. Parsers match each line and extract security-relevant fields. Non-matching lines are discarded.
4. Events go through the allowlist check, and allowlisted IPs are dropped and logged.
5. Scenarios evaluate the events over time and across sources.
6. On overflow, CrowdSec raises an alert.

**Postcondition:** Malicious behavior is turned into alerts, while legitimate, allowlisted, and unparseable traffic raises none.

**Threatened by:**

- MC-1.1: Forge log entries to frame a trusted IP
- MC-1.2: Send oversized / gzip-bomb payload to a log datasource
- MC-1.3: Spread attack across many IPs below thresholds

**Requirements:** SR-1.1 to SR-1.5

| Round | Misuse case | Misuser | Security function | CrowdSec evidence | Status |
|---|---|---|---|---|---|
| 1 | MC-1.1 Forge log entries to frame a trusted IP | Log-Forging Outsider | SF-1.1 Match strict Hub parsers; drop allowlisted IPs | Grok-based Hub parsers only emit events for lines that match; parser whitelists and [centralized allowlists](https://docs.crowdsec.net/docs/local_api/centralized_allowlists) drop local alerts for listed IPs and log the action | implemented |
| 2 | MC-1.2 Send oversized / gzip-bomb payload to a log datasource | Credentialed Log-Pusher | SF-1.2 Authenticate log sources; cap body size | [GHSA-g2x2-jgfg-pg7g](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-g2x2-jgfg-pg7g) (HTTP datasource, CVE-2026-44982) and [GHSA-rh69-4vqj-9gj8](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-rh69-4vqj-9gj8) (k8s-audit, fixed 1.8.0) | fixed after advisory |
| 3 | MC-1.3 Spread attack across many IPs below thresholds | Low-and-Slow Botnet Operator | SF-1.3 Slow/distributed scenarios + community blocklist | Hub ships slow-brute-force scenarios (e.g. `crowdsecurity/ssh-slow-bf`) and the community blocklist blocks IPs seen attacking elsewhere | implemented (coverage depends on installed collections) |

![UC-1 use/misuse case diagram](resources/static/issue3-4/uc1-use-misuse.png)

*Figure 1 — UC-1 final use/misuse case diagram.*

#### Derived requirements for UC-1

- **SR-1.1** CrowdSec shall extract security-relevant fields (source IP, user, target) only from log lines that fully match an installed parser, and shall discard non-matching lines without raising alerts.
- **SR-1.2** CrowdSec shall suppress alerts and decisions for IPs/ranges on operator-defined allowlists and shall log every suppression.
- **SR-1.3** Network log datasources (HTTP, Kubernetes audit) shall authenticate the sending log source before accepting data.
- **SR-1.4** Every network datasource shall enforce a configurable maximum raw and decompressed body size and a read timeout, rejecting oversize input without terminating the engine.
- **SR-1.5** CrowdSec shall provide scenarios that correlate low-rate activity over long windows and across many source IPs targeting the same account or resource.

### UC-2 — Inspect HTTP Request (AppSec)

An AppSec-enabled bouncer forwards each HTTP request to CrowdSec's AppSec component, which evaluates it against WAF rules and returns allow/deny.

**Primary actor:** Web App / Reverse Proxy (AppSec-enabled bouncer)

**CrowdSec feature:** AppSec component (WAF with CRS and virtual-patching rules)

**Description:** The AppSec-enabled bouncer forwards each incoming HTTP request to CrowdSec's AppSec component. AppSec evaluates the URI, headers, and body against the enabled WAF rules and returns an allow or deny verdict that the bouncer enforces.

**Preconditions:**

- AppSec is enabled, and rule sets (CRS, virtual patching) are installed.
- The bouncer is configured with the AppSec endpoint, timeouts, and failure action.

**Main flow:**

1. A client request reaches the web app or reverse proxy.
2. The bouncer forwards the request to AppSec.
3. AppSec reads the body for every framing (`Content-Length`, chunked, HTTP/2) and evaluates it against the rules.
4. AppSec returns allow or deny.
5. The bouncer allows or blocks the request accordingly.

**Postcondition:** Known-bad requests (SQLi, XSS, CVE exploits) are blocked before reaching the application.

**Threatened by:**

- MC-2.1: Send SQLi / XSS / CVE exploit payload
- MC-2.2: Hide payload with chunked / HTTP-2 body framing
- MC-2.3: Overload AppSec so requests fail open

**Requirements:** SR-2.1 to SR-2.4

| Round | Misuse case | Misuser | Security function | CrowdSec evidence | Status |
|---|---|---|---|---|---|
| 1 | MC-2.1 Send SQLi / XSS / CVE exploit payload | Remote Web Exploiter | SF-2.1 Evaluate request with CRS + virtual-patch rules | AppSec component (Coraza) with the CRS and `crowdsecurity/virtual-patching` configs | implemented |
| 2 | MC-2.2 Hide payload with chunked / HTTP-2 body framing | WAF-Evasion Specialist | SF-2.2 Read & inspect body for every framing | [GHSA-rw47-hm26-6wr7](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-rw47-hm26-6wr7) (CVE-2026-44982): versions 1.5.0–1.7.7 skipped the body when `Content-Length` was not positive | fixed after advisory (v1.7.8) |
| 3 | MC-2.3 Overload AppSec so requests fail open | WAF-Evasion Specialist | SF-2.3 Enforce timeouts; fail-closed failure action | Bouncer options `APPSEC_CONNECT_TIMEOUT`, `APPSEC_SEND_TIMEOUT`, `APPSEC_PROCESS_TIMEOUT` and `APPSEC_FAILURE_ACTION=passthrough\|deny`; [default is `passthrough`](https://docs.crowdsec.net/u/bouncers/openresty) | opt-in |

![UC-2 use/misuse case diagram](resources/static/issue3-4/uc2-use-misuse.png)

*Figure 2 — UC-2 final use/misuse case diagram.*

#### Derived requirements for UC-2

- **SR-2.1** AppSec shall evaluate the URI, headers, and body of every forwarded request against the enabled rule sets before the bouncer allows it.
- **SR-2.2** AppSec shall read and inspect request bodies for every supported framing (`Content-Length`, `Transfer-Encoding: chunked`, HTTP/2 without `content-length`), with a negative test for each framing.
- **SR-2.3** The AppSec-enabled bouncer shall enforce connect, send, and processing timeouts toward AppSec.
- **SR-2.4** The bouncer shall offer a fail-closed mode (deny when AppSec is unavailable), and every fail-open event shall be logged.

### UC-3 — Retrieve & Enforce Decisions

Remediation components authenticate to the Local API (LAPI), pull decisions, and enforce them (drop, ban, captcha). In our enterprise environment LAPI listens on the internal network so many bouncers and agents can reach it.

**Primary actor:** Remediation Component (firewall or reverse-proxy bouncer)

**CrowdSec feature:** LAPI decisions API

**Description:** A remediation component authenticates to the Local API, pulls the current decisions (banned IPs and so on), and enforces them by dropping, banning, or issuing a captcha. In the multi-server enterprise setup, LAPI listens on the internal network so many bouncers and agents can reach it.

**Preconditions:**

- The bouncer is registered with its own API key (`cscli bouncers add`).
- LAPI is reachable, ideally over TLS or mutual TLS.

**Main flow:**

1. The bouncer authenticates to LAPI with its API key (or client certificate).
2. LAPI verifies the credential and grants read-only access.
3. The bouncer pulls new and expired decisions.
4. The bouncer enforces the decisions on live traffic.
5. LAPI records the bouncer's source IP and last-pull time.

**Postcondition:** The enforcement point blocks the addresses that CrowdSec has decided to remediate.

**Threatened by:**

- MC-3.1: Query decisions with a stolen bouncer API key
- MC-3.2: Intercept or strip decisions in transit
- MC-3.3: Register rogue agent to push fake alerts
- MC-3.4: Flood login endpoint with gzip bombs

**Requirements:** SR-3.1 to SR-3.6

| Round | Misuse case | Misuser | Security function | CrowdSec evidence | Status |
|---|---|---|---|---|---|
| 1 | MC-3.1 Query decisions with a stolen bouncer API key | Bouncer-Key Thief | SF-3.1 Per-bouncer keys, read-only role, revocation | [LAPI docs](https://docs.crowdsec.net/docs/local_api/intro): bouncers use an API key and can only read decisions; machines can create them. `cscli bouncers add/delete/list` | implemented |
| 2 | MC-3.2 Intercept or strip decisions in transit | Network-Positioned Interceptor | SF-3.2 TLS / mutual-TLS with allowed OU + CRL/OCSP | [TLS auth docs](https://docs.crowdsec.net/docs/local_api/tls_auth): `agents_allowed_ou`, `bouncers_allowed_ou`, OCSP and CRL checks | opt-in |
| 3 | MC-3.3 Register rogue agent to push fake alerts | Rogue-Agent Registrant | SF-3.3 Machine validation; token + `allowed_ranges` | [Multi-server guide](https://docs.crowdsec.net/u/user_guides/multiserver_setup/): machines must be validated, or auto-register with a token **and** allowed IP ranges | implemented |
| 4 | MC-3.4 Flood login endpoint with gzip bombs | Pre-Auth LAPI Flooder | SF-3.4 Loopback default; cap decompressed size | [GHSA-273h-gvwr-c3qj](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-273h-gvwr-c3qj) (CVE-2026-44981); LAPI listens on loopback by default | fixed after advisory |

![UC-3 use/misuse case diagram](resources/static/issue3-4/uc3-use-misuse.png)

*Figure 3 — UC-3 final use/misuse case diagram.*

#### Derived requirements for UC-3

- **SR-3.1** LAPI shall issue a unique credential per bouncer and allow each credential to be revoked individually.
- **SR-3.2** Bouncer credentials shall only permit reading decisions; creating, changing, or deleting alerts and decisions shall require machine credentials.
- **SR-3.3** LAPI shall record each bouncer's source IP and last-pull time for audit.
- **SR-3.4** LAPI shall support TLS for all agent and bouncer traffic, and mutual-TLS authentication restricted to configured OUs with revocation checking.
- **SR-3.5** A newly registered machine shall not be able to push alerts until an administrator validates it, or until it registers with a secret token from an allowed IP range.
- **SR-3.6** LAPI shall bind to loopback by default and shall bound the decompressed size of every request, including unauthenticated endpoints.

### UC-4 — Manage Policy & Detection Content

The SOC Administrator uses `cscli` and configuration files to install Hub content, manage decisions and allowlists, and configure profiles.

**Primary actor:** SOC Administrator (`cscli`, config files)

**CrowdSec feature:** `cscli`, Hub, allowlists, profiles, simulation mode

**Description:** The SOC administrator installs and updates Hub content (parsers, scenarios, collections), manages decisions and allowlists, and configures profiles. This use case defines what CrowdSec detects and what it acts on.

**Preconditions:**

- The administrator has shell access to the LAPI host and OS rights to run `cscli`.

**Main flow:**

1. The administrator installs or upgrades Hub items with `cscli`.
2. `cscli` flags locally modified items as tainted and won't overwrite them without `--force`.
3. The administrator edits allowlists, decisions, or configuration.
4. The configuration is validated with `crowdsec -t`.
5. New scenarios are optionally run in simulation mode before issuing decisions.
6. CrowdSec activates the new configuration.

**Postcondition:** Detection content and policy are updated, validated, and active.

**Threatened by:**

- MC-4.1: Get a poisoned scenario/parser installed from the Hub
- MC-4.2: Quietly allowlist an accomplice's IP
- MC-4.3: Activate a broken config that blinds detection

**Requirements:** SR-4.1 to SR-4.5. SR-4.3 and SR-4.4 are gaps: there is no per-operator attribution or role separation in `cscli`.

| Round | Misuse case | Misuser | Security function | CrowdSec evidence | Status |
|---|---|---|---|---|---|
| 1 | MC-4.1 Get a poisoned scenario/parser installed from the Hub | Malicious Hub Contributor | SF-4.1 Hub review + tests; flag tainted items | Hub PRs are reviewed and run through Hub tests; `cscli` marks locally modified items as *tainted* and [`hub upgrade` will not overwrite them without `--force`](https://docs.crowdsec.net/docs/cscli/cscli_hub_upgrade) | implemented |
| 2 | MC-4.2 Quietly allowlist an accomplice's IP | Insider SOC Analyst | SF-4.2 Per-operator audit trail & RBAC for cscli | `cscli` acts with whatever OS rights the user has and writes directly to the database; we found no per-operator identity or role separation in the documentation we reviewed | **GAP** |
| 3 | MC-4.3 Activate a broken config that blinds detection | Insider SOC Analyst | SF-4.3 Validate config (`crowdsec -t`); simulation mode | `crowdsec -t` tests configuration without starting; `cscli simulation` runs scenarios without issuing decisions | implemented |

![UC-4 use/misuse case diagram](resources/static/issue3-4/uc4-use-misuse.png)

*Figure 4 — UC-4 final use/misuse case diagram.*

#### Derived requirements for UC-4

- **SR-4.1** Hub content shall pass automated Hub tests and maintainer review before publication.
- **SR-4.2** `cscli` shall detect and report Hub items whose local content differs from the published version, and shall not overwrite them silently.
- **SR-4.3** Security-sensitive administrative actions (manual decisions, allowlist changes, machine/bouncer add or delete) shall be attributable to an individual operator. *(gap)*
- **SR-4.4** `cscli` shall support separating read-only analyst roles from administrator roles. *(gap)*
- **SR-4.5** CrowdSec shall reject invalid configuration before activation, and shall let new scenarios run in simulation mode before they issue decisions.

### UC-5 — Exchange Threat Intelligence

The engine sends signals about local attacks to CrowdSec's Central API and pulls the community blocklist back.

**Primary actor:** CrowdSec Central API (CAPI)

**CrowdSec feature:** Signal sharing and community blocklist

**Description:** The engine sends signals about local attacks to CrowdSec's Central API and pulls back the community blocklist, so that IPs seen attacking elsewhere can be blocked locally.

**Preconditions:**

- The instance is enrolled with CAPI, with credentials in `online_api_credentials.yaml`.
- Sharing preferences are set in `console.yaml`.

**Main flow:**

1. LAPI connects to CAPI over HTTPS with its per-instance credentials.
2. LAPI shares signals about local attacks, according to the sharing settings.
3. LAPI pulls the community blocklist.
4. Local allowlists are applied before decisions are stored.
5. Bouncers enforce the resulting decisions (see UC-3).

**Postcondition:** Local defenses benefit from community intelligence, and local detection keeps working if CAPI is unreachable.

**Threatened by:**

- MC-5.1: Report fake signals to blocklist a victim IP
- MC-5.2: Poisoned entry blocks a partner IP locally
- MC-5.3: Impersonate CAPI / tamper with the blocklist feed
- MC-5.4: Harvest internal data from shared signals

**Requirements:** SR-5.1 to SR-5.6

| Round | Misuse case | Misuser | Security function | CrowdSec evidence | Status |
|---|---|---|---|---|---|
| 1 | MC-5.1 Report fake signals to blocklist a victim IP | Sybil Blocklist Poisoner | SF-5.1 Multi-source consensus before blocklisting | Diversity-based trust scoring (see our proposal) runs inside the CAPI service, not in the OSS repo | service-side |
| 2 | MC-5.2 Poisoned entry blocks a partner IP locally | Sybil Blocklist Poisoner | SF-5.2 Filter blocklist pulls through local allowlists | [Allowlists](https://docs.crowdsec.net/docs/local_api/centralized_allowlists) remove listed IPs from blocklist pulls before database insertion | implemented |
| 3 | MC-5.3 Impersonate CAPI / tamper with the blocklist feed | Upstream Traffic Interceptor | SF-5.3 TLS to CAPI with per-instance credentials | CAPI is reached over HTTPS using `online_api_credentials.yaml` | implemented |
| 4 | MC-5.4 Harvest internal data from shared signals | Signal-Data Harvester | SF-5.4 Minimal sharing; context off by default | `console.yaml` defaults in [`pkg/csconfig/console.go`](https://github.com/crowdsecurity/crowdsec/blob/v1.5.3/pkg/csconfig/console.go): `share_context` and `share_manual_decisions` off; `share_custom` and `share_tainted` on | implemented (partially — custom/tainted sharing is on by default) |

![UC-5 use/misuse case diagram](resources/static/issue3-4/uc5-use-misuse.png)

*Figure 5 — UC-5 final use/misuse case diagram.*

#### Derived requirements for UC-5

- **SR-5.1** A community-blocklist entry shall require reports from multiple independent, trusted sources before distribution. *(service-side)*
- **SR-5.2** Local allowlists shall be applied to blocklist pulls before any decision is stored.
- **SR-5.3** Every decision shall record its origin (local scenario, cscli, CAPI, list) so that blocklist-derived decisions can be identified and removed selectively.
- **SR-5.4** LAPI-to-CAPI traffic shall use TLS with server-certificate verification and per-instance credentials.
- **SR-5.5** Local detection and already-pulled decisions shall keep working when CAPI is unreachable.
- **SR-5.6** Signals shared upstream shall exclude alert context and manual decisions unless the operator opts in.

## Coverage check

- **Every misuse case is mitigated.** Each of the 17 misuse cases has exactly one `«mitigates»` edge. Two of those security functions are not in the OSS code (SF-4.2 GAP, SF-5.1 service-side) and are drawn dashed so the reader can see them.
- **Every proposal threat is covered.** T1 → MC-3.2, 3.3, 3.4, 4.2 · T2 → MC-3.1, 3.3 · T3 → MC-1.1, 1.2, 1.3, 2.1, 2.2 · T4 → MC-4.1, 5.1, 5.2, 5.3 · T5 → MC-3.1, 3.2 · T6 → out of scope (not an actor interaction) · T7 → MC-1.2, 2.3, 3.4.
- **Iteration found a new threat.** MC-5.4 (data exposure through shared signals) was not in our proposal's threat list; it appeared only once we asked what remains after the blocklist feed is authenticated.

---

## Derived requirements vs. CrowdSec's actual features

We checked each of the 26 requirements derived above (SR-1.1 to SR-5.6) against the CrowdSec v1.8.1 source code (release of 3 September 2026), the v1.8 documentation, the NGINX/OpenResty bouncer (`lua-cs-bouncer`), the Hub repository and the published security advisories. We did not test a running system.

A requirement is **fully covered** if a documented feature meets it, by default or with documented configuration. It is **partially covered** if it is met only with extra configuration, only for some components or deployments, or with known gaps. It is **missing** if we found no matching feature; for those we record what we searched. It is **not verifiable** if the feature runs in CrowdSec's hosted service rather than in the open-source code.

**Result: 15 fully covered, 8 partially covered, 2 missing, 1 not verifiable.**

| SR | Requirement | Verdict | Why | Evidence |
| --- | --- | --- | --- | --- |
| 1.1 | Extract security-relevant fields only from log lines that fully match an installed parser, and discard non-matching lines without raising alerts. | Full | Parsers are grok-based. A line that no parser in a stage matches is marked unparsed and discarded before it reaches any scenario. | [node.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/parser/node.go#L181) |
| 1.2 | Suppress alerts and decisions for IPs/ranges on operator-defined allowlists, and log every suppression. | Full | Each suppression path writes an info-level log line saying what matched: LAPI alert intake, blocklist pulls, parser whitelists on overflow, and the AppSec bypass. The log doesn't say who added the entry (see SR-4.3). | [alerts.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/v1/alerts.go#L182) |
| 1.3 | Network log datasources (HTTP, Kubernetes audit) shall authenticate the sending log source before accepting data. | Partial | The HTTP datasource refuses to start without an `auth_type` (basic auth, headers or mTLS). The Kubernetes-audit datasource has no authentication option at all in v1.8.1. The 1.8.0 fix for GHSA-rh69-4vqj-9gj8 added a size cap, not authentication. | [http/config.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/acquisition/modules/http/config.go#L103-L126) · [kubernetesaudit/config.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/acquisition/modules/kubernetesaudit/config.go) · [GHSA-rh69-4vqj-9gj8](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-rh69-4vqj-9gj8) |
| 1.4 | Every network datasource shall enforce a configurable maximum raw and decompressed body size and a read timeout, rejecting oversize input without terminating the engine. | Partial | Both datasources now default to a configurable 10 MB cap, added after GHSA-g2x2-jgfg-pg7g and GHSA-rh69-4vqj-9gj8. Read timeouts are weaker: the HTTP datasource sets one only if `timeout` is configured, and the Kubernetes-audit datasource has none. | [http/run.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/acquisition/modules/http/run.go#L219) · [GHSA-g2x2-jgfg-pg7g](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-g2x2-jgfg-pg7g) |
| 1.5 | Provide scenarios that correlate low-rate activity over long windows and across many source IPs targeting the same account or resource. | Partial | Slow brute-force scenarios exist (for example `crowdsecurity/ssh-slow-bf`), but all of them group events by source IP. No Hub brute-force scenario groups attempts on one account across many IPs. The scenario language can group by account, but no official scenario does. | [ssh-slow-bf.yaml](https://github.com/crowdsecurity/hub/blob/master/scenarios/crowdsecurity/ssh-slow-bf.yaml) |
| 2.1 | AppSec shall evaluate the URI, headers, and body of every forwarded request against the enabled rule sets before the bouncer allows it. | Full | The runner passes the URI, every header and the body to Coraza and returns allow or deny before the bouncer acts. | [appsec_runner.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/acquisition/modules/appsec/appsec_runner.go#L213-L227) |
| 2.2 | AppSec shall read and inspect request bodies for every supported framing (`Content-Length`, `Transfer-Encoding: chunked`, HTTP/2 without `content-length`), with a negative test for each framing. | Partial | Since the 1.7.8 fix for CVE-2026-44982 the engine reads chunked and HTTP/2 bodies, but v1.8.1 has no test for either framing. The NGINX bouncer also forwards HTTP/2 and HTTP/3 requests without a content length with no body at all unless `APPSEC_DROP_UNREADABLE_BODY` is enabled, and it is off by default. | [CVE-2026-44982](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-rw47-hm26-6wr7) · [request.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/appsec/request.go#L326) · [config.lua](https://github.com/crowdsecurity/lua-cs-bouncer/blob/ec94d512927cf70be865686e4eb928d128189633/lib/plugins/crowdsec/config.lua#L23-L29) |
| 2.3 | The AppSec-enabled bouncer shall enforce connect, send, and processing timeouts toward AppSec. | Full | The bouncer enforces all three, with defaults of 100 ms to connect, 100 ms to send and 500 ms for processing. | [config.lua](https://github.com/crowdsecurity/lua-cs-bouncer/blob/ec94d512927cf70be865686e4eb928d128189633/lib/plugins/crowdsec/config.lua#L23-L29) |
| 2.4 | The bouncer shall offer a fail-closed mode (deny when AppSec is unavailable), and every fail-open event shall be logged. | Partial | `APPSEC_FAILURE_ACTION=deny` provides fail-closed mode; the default is passthrough. Errors and timeouts are logged at error level, but a request forwarded without its body is logged only at debug level, so that fail-open goes unrecorded by default. | [NGINX bouncer docs](https://docs.crowdsec.net/u/bouncers/nginx) · [config.lua](https://github.com/crowdsecurity/lua-cs-bouncer/blob/ec94d512927cf70be865686e4eb928d128189633/lib/plugins/crowdsec/config.lua#L23-L29) |
| 3.1 | LAPI shall issue a unique credential per bouncer and allow each credential to be revoked individually. | Full | `cscli bouncers add` issues one key per bouncer and `cscli bouncers delete` revokes it. | [clibouncer/add.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec-cli/clibouncer/add.go) · [delete.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec-cli/clibouncer/delete.go) |
| 3.2 | Bouncer credentials shall only permit reading decisions; creating, changing, or deleting alerts and decisions shall require machine credentials. | Full | Bouncer keys reach only the decision read routes and `POST /v1/usage-metrics`. Every write route sits behind machine authentication. | [controller.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/controller.go#L132-L156) |
| 3.3 | LAPI shall record each bouncer's source IP and last-pull time for audit. | Full | LAPI stores each bouncer's IP address and updates a last-pull timestamp, shown by `cscli bouncers list`. | [database/bouncers.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/database/bouncers.go#L132-L146) |
| 3.4 | LAPI shall support TLS for all agent and bouncer traffic, and mutual-TLS authentication restricted to configured OUs with revocation checking. | Partial | TLS and mTLS with `agents_allowed_ou` and `bouncers_allowed_ou` are supported but off by default. Revocation checking fails open: with no `crl_path` the CRL check is skipped, and certificates without an OCSP URL skip OCSP. | [tls_auth.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/tls_auth.go#L51-L65) · [TLS authentication docs](https://docs.crowdsec.net/docs/local_api/tls_auth) |
| 3.5 | A newly registered machine shall not be able to push alerts until an administrator validates it, or until it registers with a secret token from an allowed IP range. | Full | Machines are created unvalidated and stay unusable until `cscli machines validate`. Auto-registration needs a token, and LAPI refuses to start if it is enabled without `allowed_ranges`. | [database/machines.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/database/machines.go#L140) · [csconfig/api.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/api.go#L546) |
| 3.6 | LAPI shall bind to loopback by default and shall bound the decompressed size of every request, including unauthenticated endpoints. | Partial | Every request body is capped after decompression (2 MiB unauthenticated, 50 MiB authenticated), added after CVE-2026-44981. The packages bind to `127.0.0.1:8080`, but the official Docker image binds to `0.0.0.0:8080`. | [body_limit.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/body_limit.go#L12-L13) · [docker config.yaml](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/build/docker/config.yaml#L36) · [CVE-2026-44981](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-273h-gvwr-c3qj) |
| 4.1 | Hub content shall pass automated Hub tests and maintainer review before publication. | Full | Hub CI runs configuration and AppSec-rule tests on pull requests, which maintainers then merge. We confirmed the tests in the repository but found no written review policy to check against. | [hub CI workflows](https://github.com/crowdsecurity/hub/tree/master/.github/workflows) |
| 4.2 | `cscli` shall detect and report Hub items whose local content differs from the published version, and shall not overwrite them silently. | Full | Locally modified items are marked tainted, and an upgrade will not overwrite a tainted item without `--force`. | [cwhub/sync.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/cwhub/sync.go#L376-L386) |
| 4.3 | Security-sensitive administrative actions (manual decisions, allowlist changes, machine/bouncer add or delete) shall be attributable to an individual operator. | **Missing** | There is no audit log. Manual decisions record the machine, not the person, and allowlist changes and machine or bouncer deletions record nothing. Searched the docs and source for "audit", "audit trail" and "activity log". | [clidecision/decisions.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec-cli/clidecision/decisions.go#L298) (records the machine only) |
| 4.4 | `cscli` shall support separating read-only analyst roles from administrator roles. | **Missing** | `cscli` has no roles: anyone who can run it as root is a full administrator. The paid Console has roles, but that does not satisfy a requirement on `cscli`. Searched for "RBAC", "role" and "permission". | [LAPI authentication docs](https://docs.crowdsec.net/docs/local_api/authentication) (two roles only: bouncer and machine) |
| 4.5 | Reject invalid configuration before activation, and let new scenarios run in simulation mode before they issue decisions. | Full | Strict parsing aborts startup on any error, the systemd unit runs `crowdsec -t` before every start and reload, and `cscli simulation` runs scenarios without issuing decisions. | [crowdsec.service](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/config/crowdsec.service#L8-L12) · [csconfig/config.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/config.go#L64) · [clisimulation](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec-cli/clisimulation/simulation.go) |
| 5.1 | A community-blocklist entry shall require reports from multiple independent, trusted sources before distribution. | Not verifiable | Consensus runs inside CrowdSec's hosted service. The docs say signals from modified scenarios are ignored, but the algorithm is not published. | [Community Blocklist docs](https://docs.crowdsec.net/docs/central_api/community_blocklist) |
| 5.2 | Local allowlists shall be applied to blocklist pulls before any decision is stored. | Full | The pull routine updates allowlists before it processes decisions, so allowlisted addresses never reach the database. They start empty, so an operator has to fill them. | [apic.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/apic.go#L636-L639) |
| 5.3 | Every decision shall record its origin (local scenario, cscli, CAPI, list) so that blocklist-derived decisions can be identified and removed selectively. | Full | Seven origins are defined and carried on every decision; `cscli decisions` can list and delete by origin. | [types/constants.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/types/constants.go#L10-L30) |
| 5.4 | LAPI-to-CAPI traffic shall use TLS with server-certificate verification and per-instance credentials. | Full | CAPI is reached over HTTPS with certificate verification and per-instance machine credentials. See the note below. | [Central API docs](https://docs.crowdsec.net/docs/central_api/intro) · [apic.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/apic.go#L232) |
| 5.5 | Local detection and already-pulled decisions shall keep working when CAPI is unreachable. | Partial | A running LAPI keeps working through CAPI outages. At startup, though, it must authenticate to CAPI unless a valid token is cached, and if that fails LAPI does not start. | [apic.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/apic.go#L244) |
| 5.6 | Signals shared upstream shall exclude alert context and manual decisions unless the operator opts in. | Full | `share_context` and `share_manual_decisions` both default to false in v1.8.1. Custom and tainted scenarios are shared by default, which this requirement does not cover. | [csconfig/console.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/console.go#L72-L99) |

**Note on SR-5.4.** The CAPI channel meets the requirement, but we found two related problems. First, the Splunk notification plugin builds its HTTP client with `InsecureSkipVerify: true` hard-coded. There is no setting to turn it off and its documentation does not mention it, so anyone who can intercept traffic to the Splunk endpoint can read or alter alerts and capture the HEC token ([main.go lines 115–117](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/notification-splunk/main.go#L115-L117)). Second, the CAPI client shares one skip-verify flag with the LAPI client, so enabling it for a self-signed LAPI certificate, as the docs suggest, would also switch off verification toward CAPI ([csconfig/api.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/api.go#L191-L195)). Both come from reading the source; neither has a published advisory, and we have not tested the second.

**Findings outside the requirement set.** A few weaknesses we found do not map to any of the 26 requirements, and we note them here so they are not lost. Hub items are hash-checked against an index that is itself unsigned, and the data files scenarios download (pattern lists, GeoIP databases) are not checked at all ([cwhub/download.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/cwhub/download.go#L56-L113)). Any validated machine can delete any decision from any address, because `trusted_ips` guards only alert deletion ([decisions.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/v1/decisions.go#L134-L155) versus [alerts.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/v1/alerts.go#L343-L354)). LAPI has no rate limiting. An unauthenticated pprof endpoint shares the metrics port ([main.go](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec/main.go#L7)), which the Docker image binds to all interfaces. And a panic in any component stops the whole engine, including detection, until systemd restarts it.

### What we found

Access control and configuration handling hold up well. Bouncer keys are unique, revocable and read-only, new machines must be validated, locally modified Hub items are protected, and bad configuration never goes live (SR-3.1, SR-3.2, SR-3.5, SR-4.2, SR-4.5). Traceability of decisions is good too: every decision has an origin, and every allowlist suppression is logged (SR-1.2, SR-5.3).

Several protections exist but are off by default. TLS, mutual TLS and revocation checking (SR-3.4), fail-closed AppSec (SR-2.4) and dropping unreadable bodies (SR-2.2) all have to be switched on by the administrator. A misuse case analysis assumes these controls are active, and the gap between what CrowdSec supports and what it enables is our main answer to whether its advertised features are sufficient.

The advisory fixes closed the reported bugs but left the requirements behind them open. Four 2026 advisories show input handling failing in shipped code, touching SR-1.3, SR-1.4, SR-2.2 and SR-3.6. Each was fixed after it was reported, and all four requirements are still only partially covered, for reasons the fixes did not touch: no authentication on the Kubernetes-audit datasource, no default read timeouts, no framing tests, and a Docker image that listens on every interface.

The insider is the misuser CrowdSec does least to stop. The only two missing requirements, per-operator attribution and role separation (SR-4.3, SR-4.4), both concern what a legitimate administrator can do unnoticed. Role separation exists only in the paid Console, which does not help anyone working in `cscli`.

Two requirements depend on content or services outside the engine. No one ships the cross-IP correlation scenarios SR-1.5 asks for, and the blocklist consensus behind SR-5.1 cannot be inspected from the open-source side.

Overall, CrowdSec's design supports most of the requirements, but its defaults switch on fewer of them than the documentation suggests. Where controls failed in shipped code, the fixes dealt with the reported bug and stopped there.

### Limitations

Findings come from documentation and source code, not from testing. We read the v1.8.1 release tag of the engine (commit `909b515`), and the current `lua-cs-bouncer` and Hub repositories as of September 2026. The findings for SR-1.2, SR-1.3, SR-1.4, SR-1.5, SR-2.2, SR-2.4, SR-3.6, SR-5.5, SR-5.6 and the SR-5.4 note rest on our reading of that code and should be confirmed by testing.

## Issue #4 — AI-Assisted Iteration and Final Diagram

### 4.1 Prompts used

We adapted the instructor's sample prompt. We added two constraints the rubric cares about: mitigations must be CrowdSec features (or be labeled a gap), and misuser names must convey motive and access. We ran the prompt once per use case, then used the follow-up prompt to push the iteration further. The UC-3 run is shown as an example.

```text
You are an expert software security requirement engineer.
Your job is to suggest misuse cases for a particular description of a use case diagram.
Misuse cases need to be introduced in stages as back and forth analysis by introducing
security countermeasures in response to a misuse case.
Prefer countermeasures that the CrowdSec open-source project itself implements, and name the
config option, cscli command, or documentation page. If CrowdSec has no such feature, label
the countermeasure GAP instead of inventing one.
Give every misuser a name that conveys their motive, resources, and access to the system.
Use this text description of a use case for the analysis.
"""
The "Remediation Component" actor (a firewall or reverse-proxy bouncer) is associated with the
"Retrieve & Enforce Decisions" use case of the CrowdSec Security Engine, deployed in a
multi-server enterprise network where the Local API listens on the internal network.
The "Retrieve & Enforce Decisions" use case has an include dependency on
"Authenticate bouncer with API key".
A "Bouncer-Key Thief" misuser performs "Query decisions with a stolen bouncer API key",
which threatens "Retrieve & Enforce Decisions".
"""
```

Follow-up prompt, repeated until the remaining misuse needed a control outside CrowdSec:

```text
Assume the countermeasure from the last stage is in place. What realistic misuse case still
remains against this use case in our enterprise environment? Give the misuser, the misuse
case, the CrowdSec countermeasure (or GAP), and one testable "shall" requirement.
```

We also gave the AI our initial use/misuse cases and asked it to critique them against the assignment rubric (contextualized misusers, OSS-implemented mitigations, depth of iteration).

### 4.2 What the AI review changed

| AI suggestion | Decision | Reason |
|---|---|---|
| Our initial mitigations, such as "Validate and Parse Security Events," are generic and could describe any product | **Accepted** | Each security function now names a CrowdSec mechanism (allowlists, bouncer read-only role, machine validation, `APPSEC_FAILURE_ACTION`, etc.). |
| Our initial version had only one round per use case, which is shallow | **Accepted** | Expanded to 3–4 rounds per use case (17 misuse cases total). |
| Add rogue agent registration to UC-3 | **Accepted after checking** | CrowdSec's own multi-server guide warns that a log processor can push arbitrary alerts and lock you out. |
| Add AppSec fail-open under load to UC-2 | **Accepted after checking** | Bouncer docs confirm the failure action defaults to `passthrough`. |
| Add pre-auth gzip-bomb DoS against LAPI | **Accepted after checking** | Matches GHSA-273h-gvwr-c3qj from our proposal. |
| Add data exposure through shared signals to UC-5 | **Accepted** | Verified the `console.yaml` sharing defaults in source; became MC-5.4. |
| Add per-user login / MFA for cscli as the mitigation for the insider | **Modified** | CrowdSec has no such feature, so we did not present it as a mitigation. Recorded it as GAP SF-4.2 instead. |
| Cryptographically sign every decision | **Rejected** | No such CrowdSec feature; transport integrity for MC-3.2 is covered by TLS/mTLS, which CrowdSec does implement. |
| CrowdSec skips the certificate revocation check when the CRL file is invalid or expired | **Accepted** | Confirmed in the [TLS auth docs](https://docs.crowdsec.net/docs/local_api/tls_auth); a revoked certificate could still be accepted, so this is a fail-open weakness in SF-3.2 worth noting. |
| Encrypt the SQLite database at rest | **Rejected** | This is an environment control (disk encryption), and the rubric asks us to prioritize OSS mitigations. |

### 4.3 Final diagram

Figure 6 is the finished diagram after the last round of iteration. It combines all five interactions, 17 misuse cases, and 17 security functions inside one CrowdSec system boundary. Each band is the same as the matching Figure 1–5, which are easier to read at full size. All six are pages in [`CrowdSec_Use_Misuse_Cases.drawio`](resources/static/issue3-4/CrowdSec_Use_Misuse_Cases.drawio).

![Final use/misuse case diagram](resources/static/issue3-4/final-use-misuse.png)

*Figure 6 — Final use/misuse case diagram: all five interactions after the last round.*

### 4.4 Reflection on the AI prompt's usefulness

We ran these prompts with Claude (Anthropic). The AI was most useful as a critic. Adding one rule to the instructor's sample prompt (every countermeasure must be a named CrowdSec feature, or be labeled GAP) stopped it from suggesting generic controls like MFA or disk encryption. It also sent us back to CrowdSec's documentation and advisories, which is where we found the auto-registration warning, the `passthrough` default for AppSec, and the signal-sharing defaults in `console.go`.

The follow-up prompt ("assume the last countermeasure exists — what remains?") was the most valuable part. It made the back-and-forth iteration concrete, and it surfaced things we had not listed in our proposal, data exposure through shared signals (MC-5.4) and the fact that CrowdSec skips certificate revocation checks when the CRL file is invalid or expired.

The biggest lesson was that the AI states things confidently even when they are not true. When it helped assemble this report, it described our notation as the one "used in class" without having seen our class materials, added notes assigning follow-up work to another teammate's issue, and at first labeled a round-1 summary as our "final" diagram. We caught each of these while reviewing and had them corrected. We now treat AI output as a first draft to verify against the documentation and the assignment, not as a finished answer.

---

### References

- CrowdSec Local API authentication — <https://docs.crowdsec.net/docs/local_api/intro>
- TLS authentication — <https://docs.crowdsec.net/docs/local_api/tls_auth>
- Multi-server setup (machine validation, auto-registration) — <https://docs.crowdsec.net/u/user_guides/multiserver_setup/>
- Centralized allowlists — <https://docs.crowdsec.net/docs/local_api/centralized_allowlists>
- `cscli hub upgrade` (tainted items) — <https://docs.crowdsec.net/docs/cscli/cscli_hub_upgrade>
- OpenResty/Nginx bouncer AppSec options — <https://docs.crowdsec.net/u/bouncers/openresty>
- Console sharing defaults — <https://github.com/crowdsecurity/crowdsec/blob/v1.5.3/pkg/csconfig/console.go>
- Security advisories: GHSA-rh69-4vqj-9gj8, GHSA-g2x2-jgfg-pg7g, GHSA-rw47-hm26-6wr7, GHSA-273h-gvwr-c3qj — <https://github.com/crowdsecurity/crowdsec/security/advisories>
- G. Sindre and A. L. Opdahl, "Eliciting security requirements with misuse cases," *Requirements Engineering*, 10(1), 2005.

#### Kowshik's Reflection

From this assignment, I learned how to turn a list of threats into concrete security requirements through misuse case analysis. Working on Issues #3 and #4, I identified misusers for each of CrowdSec's five external interactions and went back and forth between use cases and misuse cases. I learned that the first round always finds the obvious attack, and the real insight comes from asking what an attacker would do next once a defense is in place. This iteration led to findings that were not in our proposal, such as data exposure through shared threat signals and certificate revocation checks being skipped when the CRL file has expired.

The most useful part for me was grounding every mitigation in CrowdSec's actual features, documentation, and security advisories instead of generic security controls. This showed me where CrowdSec is strong, such as per-bouncer API keys and machine validation, and where it has gaps, such as no per-operator audit trail for cscli. I also found it useful to use AI to check for missed misuse cases, but I learned that AI output must be verified, because some of its claims sounded correct but were not true for our team.

I also gained more experience with GitHub by fixing automated markdown lint errors until the checks passed. Overall, this assignment helped me understand how security requirements are derived systematically and how important it is to verify every claim against the project's documentation.

#### Trung's Reflection

I was assigned to work on the security requirements for the use and misuse cases of CrowdSec, and I learned how important it is to have those requirements in place within an organization. Moreover, I was able to realize that implementing new security software requires an extensive amount of research and an understanding of the ecosystem just to establish these requirements. With the misuse cases, I also had to think about failsafes for the components of CrowdSec to prevent such situations from happening, which I found super interesting. It really makes you think realistically, rather than just in a perfectionist kind of way.

#### Leonard's Reflection

As team leader, I broke the assignment into GitHub issues that each matched one of its requirements, then checked our report against the assignment before we submitted. I learned that turning a long assignment into specific, trackable tasks makes working together as a team easier when everyone knows what needs to be done first. Each issue had to be clear enough that a teammate could finish it without guessing what "done" meant. 

My biggest technical lesson came from resolving merge conflicts. With several people editing the same markdown report, our changes often overlapped, and fixing them took longer than I expected. I learned to have the team pull before editing, work on separate branches, and split work by section so fewer people were changing the same lines at once. That time also showed me how easily a careless merge can quietly undo a teammate's work, so I started reviewing each merged file instead of assuming it came through intact.

The most useful part for me was the final requirements check. I traced each assignment requirement to the part of the report that meets it, which is the same idea as our misuse case analysis: every threat has to trace to a security requirement, and every requirement to evidence. Doing that check showed me that leading a project is less about writing the most content and more about making sure nothing falls through the gaps between everyone's pieces.

#### Hrudhay's Reflection 
My contribution was assessing how well CrowdSec's implemented features match the 26 security requirements our team derived from the misuse case analysis. I checked each one against the v1.8.1 source code, the documentation and the published advisories, and gave every requirement a verdict backed by a code or documentation reference. Reading the source turned up problems the documentation alone would have missed. The Kubernetes audit datasource has no authentication at all, revocation checking is skipped when no CRL path is configured, and the Splunk notification plugin disables TLS verification with no setting to turn it back on. The main difficulty was that my task sat at the end of a dependency chain, and the requirement numbering then changed between the draft and merged versions, which broke the mapping I had built.


# Project Proposal — CSCI-8420 Group 2

## Team

Mujib Latifi · Kowshik Chowdhury · Leonard Meredith · Trung Phan · Hrudhay Rao Chepyala

Repository: [link](https://github.com/StevePhan412/CSCI-8420-Group-2)

Project Board: [link](https://github.com/users/StevePhan412/projects/1)

## 1. Open-Source Software

### Software

#### CrowdSec

### Repository

[Github](https://github.com/crowdsecurity/crowdsec)

[DockerHub](https://hub.docker.com/r/crowdsecurity/crowdsec)

## 2. Systems Engineering View

(Issue #3)

### Hypothetical operational environment

[home / office / enterprise / bank / government — describe the setting and why users there would deploy this software]

### Systems engineering diagram

[Embed diagram image here, e.g. ![systems diagram] (diagrams/systems-view.png). Diagram should show the software's components, the actors/users involved, adjacent systems it interacts with, network zones, and trust boundaries within the chosen environment.]

## 3. Security Needs, Threats, and Features

Crowdsec represents a critical advancement in cybersecurity, addressing a prevalent and increasingly sophisticated issue: the accurate detection of IP addresses associated with VPNs or proxy services often used to conceal malicious online activity. 

VPNs and proxy services are regularly utilized by threat actors to obfuscate their identities and locations, undermining the ability of organizations to detect, attribute, and mitigate cyber threats effectively. This layer of anonymity not only conceals the origins of malicious actions but also exacerbates the complexity of preventing unauthorized intrusions and various cybercrimes.


## Security Features in the Software

### Behavioral Scenario Engine (Log-Based Detection)
* **How it works:** Analyzes ingested logs (system, auth, web server, or container logs) and applies leaky-bucket logic to correlate suspicious patterns over time.
* **Brute-Force & Password Spraying:** Detects repeated failed logins within a short time window on services like SSH, RDP, FTP, or web login forms.
* **Port Scanning & Host Enumeration:** Flags rapid reconnaissance attempts across multiple ports or endpoints from a single source.
* **Business Logic Abuse & Bot Scalping:** Identifies non-standard abusive behaviors, such as bots bulk-buying inventory (ticket scalping), shopping cart exhaustion, or rapid URL scraping.

### AppSec Component
* **How it works:** Inspects HTTP requests directly at the proxy or web server layer in real time (in-band or out-of-band) using rule sets like OWASP CRS.
* **Web Application Exploits:** Blocks SQL injection (SQLi), Cross-Site Scripting (XSS), command injection, and Path Traversal before they reach backend application code.
* **Virtual Patching (Zero-Day/1-Day Mitigations):** Shields legacy or unpatched platforms (e.g., WordPress plugins, CVE vulnerabilities) from exploit attempts while awaiting official code updates.
* **Sensitive File & Directory Hunting:** Instantly terminates requests seeking exposed config files (`.env`, `wp-config.php`, Git repositories, or backup archives).

### Decoupled Remediation Components (Bouncers)
* **How it works:** Enforces remediation decisions at varying network and application layers according to policy rules (ban, drop, redirect, or challenge).
* **Layer 3/4 Network Defense (Firewall Bouncers):** Uses nftables, iptables, or pf to drop volumetric connection attempts or port sweeps at the kernel level to conserve server CPU.
* **Bot & Scraper Mitigation (Reverse Proxy Bouncers):** Deploys through Nginx, Traefik, or Cloudflare to present CAPTCHA challenges to suspected bot traffic instead of outright bans, preserving access for valid users.
* **Application-Level Access Control (CMS/App Bouncers):** Intercepts traffic inside application runtimes (e.g., PHP, WordPress) to block access or invalidate compromised user sessions.

### Community Blocklist & Global Threat Intelligence
* **How it works:** Anonymizes, hashes, and validates attack data received from global instances through a central consensus engine, curating a shared feed of aggressive IPs.
* **Preemptive Edge Protection:** Blocks known malicious hosts and mass internet scanners before they ever initiate a connection with your server.
* **Distributed Botnet Defense:** Neutralizes distributed scanning networks by aggregating threat signals seen by other community members.
* **Noise & Log Reduction:** Drops malicious probes at the perimeter, cutting down server log clutter and alerting fatigue by eliminating background internet noise.

### Local API (LAPI) Distributed Fleet Coordination
* **How it works:** Acts as a centralized orchestration layer allowing multiple CrowdSec log processors to push alerts and share ban decisions with remediation points across an entire fleet.
* **Multi-Node / Multi-Cloud Protection:** When an IP attacks a public host or Kubernetes ingress node, the LAPI instantly distributes a ban to internal database nodes and reverse proxies across distinct clouds.
* **Lateral Movement Prevention:** Prevents an attacker who triggered a defense rule on one external service from probing secondary web properties or internal APIs on the same network.

## 4. Team Motivation

Our team selected **CrowdSec** because it is a practical open-source security project that addresses real-world cybersecurity threats. From a technical perspective, CrowdSec is useful because it can analyze system and application logs, identify suspicious behavior, generate security decisions, and work with remediation components to respond to malicious activity. Its architecture also includes different security-related components such as parsers, detection scenarios, APIs, and threat-intelligence mechanisms, which gives our team several areas to study from a software assurance perspective.

Another reason we selected CrowdSec is that it can be deployed in environments such as servers, web applications, containers, and enterprise systems. This allows our team to create a Docker-based testing environment and observe how the software processes security events and makes decisions. Having an environment that we can actually configure and evaluate makes the project more technically meaningful than only studying documentation.

CrowdSec also has publicly available source code, documentation, an active open-source community, and a history of security-related development. These resources give us opportunities to study its **architecture, security requirements, source code, vulnerabilities, security features, and development practices**.

Overall, we believe CrowdSec provides a good balance of **technical depth, real-world security value, and manageable project scope** for applying the software assurance concepts covered in this course.

## 5. Open-Source Project Description

### What it is

CrowdSec is an open-source security engine that works like Fail2Ban, but takes it a step further. Where Fail2Ban reacts to known malicious behavior on a single machine for instance, detecting a brute-force attempt and banning that IP from accessing the machine CrowdSec leverages every machine running the program to help stop known malicious IPs collectively. It records that IP and distributes it to all other machines running the service, meaning an attacker gets banned from other machines before even attempting to attack them.

### Contributors & maintainers

blotus, buxior & Jdv / CrowdSec SAS, 86 Contributors

### Activity

162 commits over 6 months (avg 27/month), 224 open issues / 1,018 closed issues (~18% of all issues are open), currently at v1.8.1 (over 223 releases)

### Popularity

14.8K stars, 715 forks

### Languages & core dependencies

- Go 83.2%
- Shell 11.7%
- Python 1.4%
- Go Template 1.3%
- HTML 0.7%
- Makefile 0.7%

Core dependencies: Docker, Go, Grok Patterns, SSH, SQLite

### Supported platforms

Checkpoint, Cisco, F5, Fortinet, Juniper, Mikrotik, OPNsense, PaloAlto, pfSense, Sophos, Linux, FreeBSD, Windows, Docker, Kubernetes, WHM, Unix Firewall, NGinx, HAProxy, Cloudflare Workers

### Documentation

- [Official Docs](https://docs.crowdsec.net/) — comprehensive documentation and wiki maintained together
- [GitHub README](https://github.com/crowdsecurity/crowdsec) — overall introduction to how CrowdSec works

## 6. License, Contribution Procedures, and Contributor Agreements

(Issue #7)

### License

[license name — confirm it's OSI-recognized open source]

### What it permits/requires

[modification, redistribution, commercial use, copyleft implications]

### Contribution process

[summary of CONTRIBUTING.md — PR process, code review norms, testing/style requirements]

### Contributor agreement

[CLA or DCO requirement, if any]

## 7. Security-Related History

## [GHSA-rh69-4vqj-9gj8](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-rh69-4vqj-9gj8): Unbounded request-body read in kubernetes-audit acquisition webhook
* **CVE ID:** N/A
* **Weaknesses:** N/A
* **Affected version:** <= 1.7.8
* **Patched version:** 1.8.0
* **Impact:** Memory-exhaustion DoS

**Summary:**
The kubernetes-audit acquisition webhook reads the entire request body with `io.ReadAll` and no size limit, no authentication, and no server read timeout. A client able to reach the webhook port can POST an arbitrarily large body, causing memory exhaustion (a denial of service of the CrowdSec agent).

---

## [GHSA-g2x2-jgfg-pg7g](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-g2x2-jgfg-pg7g): HTTP acquisition datasource lacks a decompressed body cap and trusts Content-Length
* **CVE ID:** [CVE-2026-44982](https://nvd.nist.gov/vuln/detail/CVE-2026-44982)
* **Weaknesses:** [CWE-409](https://cwe.mitre.org/data/definitions/409.html), [CWE-770](https://cwe.mitre.org/data/definitions/770.html)

**Summary:**
The HTTP acquisition datasource does not bound the size of request bodies it buffers. A client holding valid log-source credentials can send a single request that causes the Security Engine to allocate memory until the process is terminated by the OOM killer.

---

## [GHSA-rw47-hm26-6wr7](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-rw47-hm26-6wr7): CrowdSec AppSec silently drops request body for chunked / HTTP-2 requests
* **CVE ID:** N/A
* **Weaknesses:** [CWE-693](https://cwe.mitre.org/data/definitions/693.html)

**Summary:**
The CrowdSec AppSec component fails to read the HTTP request body for any request whose `Content-Length` is not positive — most notably HTTP/1.1 requests using `Transfer-Encoding: chunked` and HTTP/2 requests sent without a `content-length` header. Coraza is then evaluated against an empty body, so every WAF rule targeting `REQUEST_BODY`, `BODY_ARGS`, `ARGS_POST`, `JSON`, or `XML` silently fails to match.

An unauthenticated remote attacker can bypass the entire AppSec body-inspection pipeline by changing a single framing header on an otherwise-malicious request. The bypassed request is forwarded as allow and produces no WAF log entry.

---

## [GHSA-273h-gvwr-c3qj](https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-273h-gvwr-c3qj): CrowdSec LAPI: Denial of Service via Unbounded Gzip Decompression
* **CVE ID:** [CVE-2026-44981](https://nvd.nist.gov/vuln/detail/CVE-2026-44981)
* **Weaknesses:** [CWE-409](https://cwe.mitre.org/data/definitions/409.html)

**Details:**
* The LAPI router uses `gin-contrib/gzip` with `DefaultDecompressHandle` globally (`pkg/apiserver/controllers/controller.go`).
* This middleware decompresses incoming request bodies without enforcing a maximum decompressed size.
* The endpoints `/v1/watchers` or `/v1/watchers/login` require no authentication.
* An attacker can send small gzip-compressed JSON payloads that, when decompressed, result in hundreds of MB of valid JSON occupying server memory.
* Sending enough requests concurrently will cause LAPI to allocate excessive heap memory, leading the OS to forcibly terminate the process.
* This vulnerability is not exploitable from the network in default configurations, as LAPI only listens on the loopback interface.
* If you are using a multi-server setup, LAPI will be exposed in the network, in which case you are at risk if untrusted IPs can access it.


## 8. Reflection

(Issue #9)

### Individual reflections (what did you learn from this assignment? what did you find most useful?)

Mujib: [reflection]
Kowshik: [reflection]
Leonard: [reflection]

Trung:
I was able to learn about Intrusion Detection System and its usage within an enterprise. I am quite excited to see such a tool existed within the cyber industry and solving the very difficult challenge involving cyberattacks. I also gained more knowledge with Github to lookup CVEs, how to create pipelines and use it effectively. I think the most useful knowledge about this assignment is how even for a security software, there are still flaws and can also be a vulnerability to the system. 

Hrudhay: [reflection]

### Team reflection (compiled)

[Synthesized summary of the above — not just a list of quotes.]

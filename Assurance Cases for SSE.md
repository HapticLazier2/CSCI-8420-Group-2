# Assurance Cases for Software Security Engineering

[Github Link](https://github.com/HapticLazier2/CSCI-8420-Group-2)

[ProjectBoard Link](https://github.com/users/HapticLazier2/projects/1)

CSCI-8420 Group 2 · System of interest: CrowdSec Security Engine (v1.8.x) · Environment: enterprise network (Multi-server LAPI)
## C5: Community intelligence does not cause sustained blocking of legitimate IP addresses or undermine local detection

Contributor: [Hrudhay Rao Chepyala]

![Community Threat Intelligence](resources/static/assurane-claims/top-level-claims-subclaims-rebuttals-evidence-v1-c5.png)
<p align="center">Community Threat Intelligence</p>

### Top Claim and Context

Top claim C5 says that community intelligence does not cause sustained blocking of legitimate IP addresses or undermine local detection. It traces to UC-5 (Exchange Threat Intelligence) and SR-5.1 to SR-5.6. The case targets two misusers from our UC-5 analysis: a Sybil Blocklist Poisoner, who runs many cheap CrowdSec instances that all report a partner's IP, and an Upstream Traffic Interceptor, who sits on the path to CrowdSec's Central API (CAPI) and edits the list in transit. Assumption A5.1 states that CrowdSec's servers and consensus engine work as documented and are not compromised, which we cannot verify from the enterprise side. C5 splits into four sub-claims, each challenged by one rebutting defeater and ending in tangible evidence.

### C5.1: Community Blocklist Entries Keep a Low False-Positive Rate (SR-5.1)

R5.1 asks whether poisoned or low-confidence data from a Sybil Blocklist Poisoner could pass validation. E5.1 answers it with feed-validation rules, acceptance-test results and measured false-positive rates. CrowdSec's consensus runs on its own servers, and the documentation says only signals from unmodified Hub scenarios count, but the algorithm itself is not published. Our own measurement, checking pulled IPs against the partner register and recent customer traffic, therefore carries most of the weight. C5.1 is partly supported.

### C5.2: Local Allowlists Override Community Data (SR-5.2)

R5.2 asks whether broken rule precedence or exception handling could still block an allowlisted address. Our source review found a real case. The pull-time allowlist filter only parses single addresses, so a blocklist range such as 203.0.113.0/24 is inserted even when a partner's address is inside it. The range-aware clean-up runs only when CAPI sends allowlists in the same pull, or when an administrator runs `cscli allowlists add` or `import`. E5.2 answers with rule-precedence tests that include this range case, allowlist regression results and suppression logs. Single addresses are handled, ranges are not, so C5.2 is partly supported.

### C5.3: Community Feed Data Is Unaltered (SR-5.3)

R5.3 asks whether an Upstream Traffic Interceptor could get altered or replayed feed data accepted if TLS verification or freshness checks fail. The feed is a plain list read line by line with no signature, so its integrity depends entirely on TLS. Certificate checking toward CAPI follows a shared `insecure_skip_verify` flag, which the LAPI documentation tells administrators to enable for self-signed certificates. On a server running both the agent and LAPI, following that advice would also switch off verification toward CAPI. E5.3 answers with a TLS configuration audit, interception and replay test results, and feed-provenance records. C5.3 holds only while certificate verification stays on, so it is partly supported.

### C5.4: Community Data Cannot Remove or Degrade Local Detections (SR-5.5)

R5.4 asks whether feed deletions or bulk inserts could erase or slow down local decisions. E5.4 answers with a code review and a load test. The code review shows that CAPI deletions only expire decisions whose origin is CAPI, so the feed cannot erase local detections. The load test of the local API during blocklist insertion is planned, not yet run. C5.4 is largely supported.

## Top-Level Claim C2 — AppSec

For C5, the AI prompts caught a missing branch and method-style sub-claims, but they also invented thresholds and assumed features CrowdSec doesn’t have, so we checked every suggestion against the source before using it.

### References

- [CrowdSec v1.8.1 – csconfig/api.go L384–390 (community pull on by default)](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/api.go#L384-L390)
- [CrowdSec v1.8.1 – csconfig/api.go L190–194 (shared insecure_skip_verify flag)](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/api.go#L190-L194)
- [CrowdSec v1.8.1 – apic.go L813–848 (allowlist filter, single addresses only)](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/apic.go#L813-L848)
- [CrowdSec v1.8.1 – apic.go L678–686 (range-aware clean-up)](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/apic.go#L678-L686)
- [CrowdSec v1.8.1 – apic.go L449–477 (CAPI deletions limited to CAPI origin)](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/apic.go#L449-L477)
- [CrowdSec v1.8.1 – allowlists.go L508 (cscli allowlists add)](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec-cli/cliallowlists/allowlists.go#L508)
- [CrowdSec v1.8.1 – decisions_service.go L175–250 (unsigned feed)](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiclient/decisions_service.go#L175-L250)
- [CrowdSec docs – Community Blocklist](https://docs.crowdsec.net/docs/central_api/community_blocklist)
- [CrowdSec docs – Local API configuration](https://docs.crowdsec.net/docs/local_api/configuration)




#### Kowshik's Reflection

**Attackers I worry about:** Remote Web Exploiter, WAF-Evasion Specialist

**Comes from:** UC-2 and requirements SR-2.1 to SR-2.4 in our team's last report

### C2 assurance case diagram

![C2 AppSec assurance case](resources/static/assurance/c2-appsec-assurance-case.png)

#### Hrudhay's Reflection
I owned claim C5. I researched it against the CrowdSec v1.8.1 source code, wrote its narrative from
Mujib’s diagram. The main issues were that my claim’s scope changed midway, from supply chain to
community intelligence, and that the diagram and my text drifted apart, which left gaps we found
late. Next time, I’d confirm claim wording and conventions before starting and check in with the team
earlier.

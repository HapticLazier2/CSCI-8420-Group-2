# DFD-2 remediation path and authentication — AI STRIDE-per-interaction run

Run 18 November 2026. Model: Claude (Anthropic). Input: `threat-modeling/images/dfd2-remediation.PNG`.

## Prompt

The instructor's prompt, used verbatim, with the same CrowdSec-grounding constraint appended
as in the other two runs:

```text
For the given DFD diagram apply STRIDE per Interaction. Focus on interactions that cross
the threat boundary.
For each interaction, enumerate plausible spoofing, tampering, repudiation, information
disclosure, denial of service, and elevation of privilege threats.
Propose mitigations that align with the architecture, not fight it. For each threat,
suggest control options at the right layer, note tradeoffs, and highlight quick wins versus
structural fixes. Where appropriate, add design guardrails that prevent entire classes of
issues rather than patching symptoms.
```

## Output

This diagram nests four boundaries — Internet, Privilege, LAPI, and a conditional DB boundary
— with Remote Host separate, so almost every flow crosses something. Only `Adminstrative
Commands` (Administrator to cscli) and `Config and Credintials` stay inside one boundary. The
crossings group into six, since the three enrollment flows raise the same questions.

### 1. Interaction: Decision Stream (Req & Res), LAPI ↔ Remote Bouncer

The flow this whole diagram exists for.

**Spoofing.** A bouncer authenticates with an API key sent as a static bearer token on every
request. Anyone holding the key is that bouncer. With TLS off, nothing authenticates LAPI to
the bouncer either.

*Mitigations:* keys are per-bouncer and individually revocable (`cscli bouncers delete`), and
LAPI stores only a SHA-512 hash. Mutual TLS with `bouncers_allowed_ou` restricts which
certificates may act as a bouncer at all. Quick win: issue one key per bouncer rather than
sharing, which the tooling already encourages. Structural fix: short-lived tokens instead of
static keys. Trade-off: bouncers poll continuously, so token refresh adds a failure mode to a
path that currently cannot fail.

**Tampering.** Decisions are unsigned, so without TLS a modified decision is indistinguishable
from a real one — and the bouncer enforces whatever it receives.

*Mitigations:* TLS. **GAP:** no decision signing. Quick win: enable TLS. Structural guardrail:
sign decisions at creation and verify at the enforcement point, which would also cover the
CAPI-sourced blocklist in DFD-3.

**Repudiation.** LAPI records each bouncer's address and a last-pull timestamp, and since
v1.6.3 bouncers can report usage metrics. These are counters, not a record of which decisions
went where.

*Mitigations:* partially covered. Quick win: `cscli bouncers list` already shows last pull, so
a stale bouncer is visible. Structural fix: per-request attribution in the access log, which
currently logs an address and a self-declared user agent.

**Information disclosure.** The decision stream is the blocklist. Over plain HTTP anyone on the
path learns every address being blocked, which is operational intelligence about what the site
is seeing.

*Mitigations:* TLS. Low priority relative to the tampering case on the same flow.

**Denial of service.** **GAP.** No rate limiting anywhere in the API server. A bouncer fleet
polls continuously, so there is no baseline distinguishing a flood from normal traffic.

*Mitigations:* request bodies are bounded. Quick win: none that does not risk breaking polling.
Structural fix: rate limits that separate authentication from decision polling.

**Elevation of privilege.** Bouncer keys are read-only on decisions — they reach only the
decision read routes and `POST /v1/usage-metrics`. A compromised bouncer cannot create or delete
bans.

*Mitigations:* genuinely covered, and the strongest least-privilege result in the whole model.
Worth stating as a positive finding rather than a gap.

### 2. Interaction: Enforcement Decisions, Remote Bouncer → Protected Services

**Spoofing.** The bouncer is the enforcement point; a spoofed bouncer would block or unblock
arbitrarily.

*Mitigations:* this crossing sits outside CrowdSec — the firewall or web server trusts whatever
the bouncer tells it. Quick win: run the bouncer on the protected host rather than remotely.
Structural guardrail: treat the bouncer as part of the protected service's trust zone, not as a
remote client.

**Tampering / Repudiation / Information disclosure.** Local to the enforcement point and outside
CrowdSec's control.

**Denial of service.** A bouncer that fails open lets traffic through uninspected; one that fails
closed blocks everything. The AppSec bouncer defaults to passthrough.

*Mitigations:* `APPSEC_FAILURE_ACTION=deny` provides fail-closed. Quick win: decide the posture
deliberately rather than inheriting the default. Trade-off: this is a real availability-versus-
security choice and the right answer differs per site.

**Elevation of privilege.** Not applicable — the bouncer holds no privilege the protected service
does not grant it.

### 3. Interactions: Machine Enrollment, Bouncer Enrollment, Bouncer Registration

Three flows, one question: how does a new component get a credential?

**Spoofing.** An unregistered machine attempting to enroll. Auto-registration, where enabled,
accepts anything presenting the shared token from an allowed range.

*Mitigations:* machines are created unvalidated and stay unusable until `cscli machines
validate`; LAPI refuses to start if auto-registration is on without `allowed_ranges`. Quick win:
leave auto-registration off, which is the default. Structural fix: per-host enrollment tokens
rather than one shared secret. **Note:** the Kubernetes Helm chart's documented configuration
enables auto-registration with every private range allowed.

**Tampering.** Without TLS, an enrollment request and the credential returned can both be
modified in transit.

*Mitigations:* TLS. This is the one flow where plaintext is worst, because it carries a new
credential.

**Repudiation.** **GAP.** No record of who approved an enrollment. `cscli machines` writes to the
database directly rather than through the API.

*Mitigations:* Quick win: none. Structural fix: route `cscli machines` through the API so the
action is attributable and loggable.

**Information disclosure.** A credential crosses the wire at enrollment.

*Mitigations:* TLS, as above.

**Denial of service.** Unlimited enrollment attempts, same missing rate limit.

**Elevation of privilege.** A successfully enrolled machine holds the machine role, which can
create *and delete* every decision. Enrollment is therefore the path to the privilege gap found
in DFD-1.

*Mitigations:* **GAP.** Quick win: apply the `trusted_ips` check to decision deletion. Structural
fix: separate the log-processor role from the administrative one so enrollment grants only the
former.

### 4. Interaction: Aminstrative API Requests, cscli → LAPI

**Spoofing.** `cscli` run locally reads the credentials file directly; anyone with root is the
administrator.

*Mitigations:* file permissions. **GAP:** `cscli` has no roles — there is no read-only analyst
identity. Structural fix: role separation in `cscli`. Trade-off: the Console has roles, but that
does not help anyone working at the command line.

**Tampering / Information disclosure.** As the other LAPI crossings: TLS-dependent.

**Repudiation.** **GAP.** A manual decision records `MachineID` taken from the local credentials
file and an origin constant. Everyone with root on the host shares one identity, and deletions
record nothing at all.

*Mitigations:* Quick win: none available in the product. Structural fix: an operator field on
`cscli`-originated actions plus an append-only log. This is the single most-repeated gap across
all three diagrams.

**Denial of service.** Same missing rate limit.

**Elevation of privilege.** Local root is unrestricted by design.

### 5. Interaction: Management Communications, Console → LAPI

Covered in the DFD-3 run; the findings are identical. In summary: since v1.6.9 the engine accepts
Console decision orders automatically where the plan permits, and a Console-pushed allowlist entry
makes an address skip AppSec entirely, logged once at info level. **GAP** on both.

### 6. Interaction: Write / Read Decisions, LAPI ↔ CrowdSec Database

**Spoofing.** Pointing LAPI at a substituted database file replaces the whole decision set.

*Mitigations:* the file is created 0600. Quick win: none needed beyond host hygiene. Structural
fix: none proportionate — if an attacker can swap the database file they already have the host.

**Tampering.** **GAP.** No encryption at rest and no integrity check. A direct write changes
decisions without passing through the API or leaving a record.

*Mitigations:* Quick win: filesystem-level monitoring on the database file. Structural fix:
encryption at rest, which `db_config` does not offer.

**Repudiation.** The flush job deletes alerts after 5000 records or seven days, so evidence has a
short life by default.

*Mitigations:* Quick win: raise the retention settings. Trade-off: unbounded growth, which is what
the cap exists to prevent — the two requirements genuinely conflict and the current default
favours availability.

**Information disclosure.** Alert history, source addresses and credential hashes all sit in one
unencrypted file.

**Denial of service.** Growth is bounded by the flush settings — covered.

**Elevation of privilege.** Database write access equals LAPI administrative access, with no audit
trail.

## Design guardrails

- **Keep the bouncer read-only and make everything else match it.** The one place this model gets
  least privilege right is the bouncer: read decisions, report metrics, nothing else. The machine
  role, which can create and delete every decision, is the opposite. Scoping the machine role the
  way the bouncer role is already scoped would close the elevation class across all three diagrams.
- **Enrollment is the real boundary.** Three flows in this diagram issue credentials. Everything
  downstream inherits whatever that moment grants, so controls belong there rather than at each
  endpoint afterwards.
- **One audit decision, not twelve.** Repudiation appears on every crossing here and in both other
  diagrams, always for the same reason. An append-only log recording an operator identity answers
  the whole class.
- **Sign decisions rather than protecting each channel.** Decisions reach bouncers from LAPI, and
  LAPI from CAPI. Signing them at creation removes the tampering class on both paths at once and
  does not depend on every operator configuring TLS correctly.

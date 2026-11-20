# DFD-1 detection pipeline — AI STRIDE-per-interaction run

Run 18 November 2026. Model: Claude (Anthropic). Input: `threat-modeling/images/dfd1-detection.png`.

## Prompt

The instructor's prompt, used verbatim:

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

**Adaptation.** We appended one constraint, carried over from the misuse-case assignment:
every proposed mitigation must name an actual CrowdSec feature, configuration key or code
path, or be labelled **GAP**. Without it the model proposed generic controls (CAPTCHA, OAuth2,
WAF rules) that have no counterpart in this product.

## Output

Two interactions cross a trust boundary in this diagram. Both run from the Security Engine
(Agent), inside the Remote Host Boundary, to LAPI inside the LAPI Host Boundary. The file
reads and SQL flows stay inside a single boundary and are out of scope for this pass.

### 1. Interaction: Machine login (HTTP/S POST), Agent → LAPI

**Spoofing.** An attacker who reads the agent's credentials file becomes that agent. The
password is bcrypt-hashed server-side but stored in plaintext on the agent. With TLS off,
nothing authenticates LAPI to the agent either, so a man-in-the-middle can harvest
credentials.

*Mitigations:* machine validation already blocks unapproved agents (`cscli machines validate`).
Mutual TLS with `agents_allowed_ou` restricts which certificates may act as an agent.
Quick win: enable TLS in `config.yaml` — `insecure_skip_verify` already defaults to false,
so certificate checking comes on with it. Structural fix: require mTLS on any listener not
bound to loopback. **GAP:** revocation fails open — with no `crl_path` the CRL check is
skipped, so a stolen certificate keeps working. Trade-off: mTLS adds certificate
distribution and rotation work that small deployments will skip, which is probably why it
is off by default.

**Tampering.** Without TLS the login request is modifiable in transit.

*Mitigations:* TLS is the whole mitigation here and it exists. Quick win: turn it on.
Structural fix: refuse to start when the listen address is non-loopback and TLS is unset,
rather than warning. Trade-off: that would break existing installs on upgrade.

**Repudiation.** Login attempts, successful or failed, are recorded only in an access log
carrying a client IP and a self-declared user agent.

*Mitigations:* **GAP.** There is no audit log in CrowdSec. Quick win: extend the existing
access-log middleware to record the authenticated machine name, which LAPI already knows
from the token. Structural fix: an append-only audit log for authentication and
administrative events, separate from the alert database so the flush job cannot prune it.

**Information disclosure.** Machine ID and password cross the network in cleartext in a
default multi-host install. The documented multi-server setup binds LAPI to `0.0.0.0`
without making TLS a required step.

*Mitigations:* TLS. Quick win: enable it before following the multi-server guide.
Structural fix: change that guide so TLS is a step rather than an option.

**Denial of service.** **GAP.** There is no rate limiting anywhere in the API server, so
the login endpoint accepts unlimited attempts — credential stuffing and resource exhaustion
both.

*Mitigations:* Quick win: per-IP throttling on `/v1/watchers/login` only, which is cheap and
low-risk. Structural fix: a general rate-limit middleware across the API. Trade-off: a
legitimate bouncer fleet polls frequently, so limits must distinguish authentication from
decision polling or they will break enforcement.

**Elevation of privilege.** Any validated machine can delete every decision in the system,
from any address. `trusted_ips` is checked on alert deletion and not on decision deletion.

*Mitigations:* **GAP.** Quick win: apply the `authIP` check already used by the alert-delete
handlers to `DeleteDecisionById` and `DeleteDecisions` — the function exists and is called
four lines away in a sibling file. Structural fix: per-machine scopes, so a log processor can
create decisions but not delete them. Trade-off: `cscli` relies on machine credentials for
administrative work, so scoping needs a separate administrative role first.

### 2. Interaction: Alerts (HTTP/S POST), Agent → LAPI

**Spoofing.** A compromised agent submits alerts for addresses it never observed. Alerts may
carry decisions directly, so this is ban creation.

*Mitigations:* machine validation gates who may submit at all. LAPI allowlists drop
alerts for protected addresses before they are stored. Quick win: populate the allowlist with
administrative and infrastructure ranges — it exists and ships empty. Structural fix:
per-machine scoping so an agent may only raise alerts for sources it actually parsed.
Trade-off: that requires LAPI to know each agent's monitored scope, which it currently does not.

**Tampering.** Alert contents are modifiable without TLS, and the resulting decision is
enforced by every bouncer.

*Mitigations:* TLS as above. **GAP:** decisions carry no signature, so a modified alert is
indistinguishable from a legitimate one once stored. Structural guardrail: sign decisions at
creation and verify at the enforcement point.

**Repudiation.** Alerts do record the submitting machine — `MachineID` is set server-side from
the authenticated token, not from the request body.

*Mitigations:* this one is genuinely covered. The residual gap is that a machine is not a
person: everyone with root on a host shares one identity. Quick win: none available.
Structural fix: operator identity on `cscli`-originated decisions.

**Information disclosure.** Alert bodies carry attacker addresses, geolocation and the
triggering log lines, in cleartext without TLS.

*Mitigations:* TLS. Trade-off: none worth noting; this is the same control as every other
row and the reason it belongs in the guardrails below rather than in six separate fixes.

**Denial of service.** Oversized alert bodies are bounded — 2 MiB unauthenticated and 50 MiB
authenticated, measured after decompression.

*Mitigations:* present, in `body_limit.go`. Worth noting that this control was added after a
gzip-decompression advisory rather than designed in. Quick win: none needed. Structural fix:
pair the size bound with a rate bound, since size alone does not stop a flood of small alerts.

**Elevation of privilege.** Alert submission is decision creation. Combined with unrestricted
deletion, one agent credential is full control of the blocklist.

*Mitigations:* as in interaction 1. This is the same root cause seen from the other direction,
and it is why the fix belongs at the authorization layer rather than per-endpoint.

## Design guardrails

- **Make the trust boundary enforce something.** Today an agent crossing from the Remote Host
  Boundary into the LAPI Host Boundary presents a credential and is then trusted for every
  operation the machine role permits. Scoping that role — create but not delete, alert on
  observed sources only — removes the elevation class rather than patching two handlers.
- **Default to encrypted transport for any non-loopback listener.** TLS is the mitigation for
  spoofing, tampering and information disclosure on both interactions. One default change
  closes three STRIDE categories across every cross-boundary flow.
- **Separate the audit record from the operational database.** Repudiation recurs on every
  interaction because the only durable record is the alert table, which the flush job prunes
  after seven days. An append-only log outside that lifecycle answers the whole class.
- **Bound rate as well as size.** The body-size limits show the pattern is understood; applying
  it to request frequency closes the denial-of-service class at the same layer.
- **Fail closed on revocation.** A control that silently skips when unconfigured is worse than
  no control, because it reports success. This applies to CRL and OCSP checking today and is
  the same shape as the hash-mismatch handling found in DFD-3.

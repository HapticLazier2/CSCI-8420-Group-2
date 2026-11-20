# DFD-3 external and cloud — AI STRIDE-per-interaction run

Run 18 November 2026. Model: Claude (Anthropic). Input: `threat-modeling/dfd3-external/dfd3-external-cloud.png`.

## Prompt

The instructor's prompt, used verbatim, with the same CrowdSec-grounding constraint appended
as in the DFD-1 run:

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

Five interactions cross between the Admin Local API boundary and the Cloud Server boundary.
`control`, `store` and `View alerts` stay within a single boundary and are out of scope.

### 1. Interaction: Request config / Download parsers and scenarios, cscli ↔ CrowdSec Hub

This pair is the most exposed crossing in the diagram and the one the Threat Modeling Tool
said least about.

**Spoofing.** The hub index is fetched from `cdn-hub.crowdsec.net` with no signature of any
kind. Whoever controls that CDN, or the TLS path to it, controls what detection content every
engine installs.

*Mitigations:* HTTPS is in place and `hub_url_template` can be pointed at an internal mirror.
Quick win: mirror the hub internally and pin the URL, which bounds who can serve content even
without signing. Structural fix: sign the index and verify against a pinned key before use.
**GAP** — no signing exists today. Trade-off: an internal mirror adds a sync job and delays
upstream fixes reaching production.

**Tampering.** Hub items are SHA-256 checked, but against hashes carried in that same
unverified index, so tampering with the index defeats the check. Data files — pattern lists,
GeoIP databases — are not hash-checked at all; the downloader only writes the file and
compares content.

*Mitigations:* **GAP** on both. Quick win: maintain a local digest inventory of installed
items and data files and verify before reload, which can be done outside CrowdSec with
`sha256sum -c`. Structural fix: carry data-file digests in the index and verify on download,
then sign the index so the digests themselves are trustworthy.

**Repudiation.** A failed integrity check is logged as "The index file is outdated, please run
`cscli hub update`" and returns no error. The packaged updater runs `cscli --error`, which
sets the log level above warnings, so the message never appears.

*Mitigations:* **GAP.** Quick win: remove `--error` from `hubupdate.sh` so warnings survive, and
alert on the string. Structural fix: return a non-zero error on hash mismatch rather than
treating it as staleness. Trade-off: failing the update on mismatch could leave an engine on
stale content during a genuine index-propagation delay, which is presumably why it was written
this way.

**Information disclosure.** Which collections an engine installs reveals what software the site
runs. Low severity.

*Mitigations:* an internal mirror removes the signal from the upstream vendor's view. Not worth
a structural change on its own.

**Denial of service.** If the CDN is unreachable the daily update fails silently and the engine
continues on existing content. The shipped update script has no retry.

*Mitigations:* existing content keeps working, so availability of detection is preserved. Quick
win: add retry to the update wrapper. Structural fix: alert when the last successful update
exceeds a threshold, so silent staleness becomes visible.

**Elevation of privilege.** Updates run daily from a systemd timer — update, upgrade, reload —
with no review step. Poisoned or faulty content reaches every engine within 24 hours and runs
with the engine's privileges.

*Mitigations:* `cscli hub` marks locally modified items tainted and will not overwrite them
without `--force`, and simulation mode can run new scenarios without enforcing.
Quick win: disable `crowdsec-hubupdate.timer` and run updates through change control.
Structural fix: gate upgrades behind an approval and an alert-only soak before they enforce.
Trade-off: this is the sharpest trade in the whole model — the same automation is the
availability mitigation for the denial-of-service row above. Automatic updates buy freshness
and cost review.

### 2. Interaction: Send offender IPs, LAPI → CAPI

**Spoofing.** CAPI is reached over HTTPS at a hard-coded base URL with per-instance credentials,
and certificate verification is on unless explicitly disabled.

*Mitigations:* covered. One caveat: the skip-verify flag is shared between the LAPI and CAPI
clients, so disabling verification for a self-signed LAPI certificate also disables it toward
CAPI. Quick win: never set `insecure_skip_verify`; use a proper certificate on LAPI instead.
Structural fix: separate the two flags.

**Tampering.** Signals are protected by the TLS session only; nothing signs the payload.

*Mitigations:* **GAP.** Acceptable for outbound telemetry given the TLS channel. Not worth a
structural fix in this direction.

**Repudiation.** Push results appear in ordinary logs. There is no durable record that a given
signal was sent and accepted.

*Mitigations:* **GAP**, same root cause as everywhere else in this model.

**Information disclosure.** Signals carry the scenario name, hash and version, a timestamp, the
machine ID and the attacking address with geolocation. Alert context and manual decisions are
excluded unless the operator opts in — `share_context` and `share_manual_decisions` both default
to false.

*Mitigations:* the minimisation is real and is a genuine design strength. Quick win: confirm
those two flags after enrolling in the Console, since enrolment turns them on. Structural fix:
none needed.

**Denial of service.** Signals accumulate in an in-memory cache and are flushed on shutdown. A
restart during an outage loses them.

*Mitigations:* partial. Quick win: none. Structural fix: persist the outbound queue. Trade-off:
durability costs disk writes on a hot path for data that is advisory rather than enforcing.

**Elevation of privilege.** Not applicable in this direction — the engine is the client and
gains nothing from the interaction.

### 3. Interaction: Transfer community blocklist, CAPI → LAPI

**Spoofing.** Same TLS protections as interaction 2, in the receiving direction.

*Mitigations:* covered by certificate validation.

**Tampering.** Blocklist content is unsigned beyond the TLS session, and these entries become
enforced bans.

*Mitigations:* **GAP.** Local allowlists are applied before decisions are stored, which bounds
the damage to addresses the operator has not protected. Quick win: populate the allowlist with
infrastructure, administrative and customer ranges. Structural fix: sign blocklist payloads.
Trade-off: allowlists require the operator to predict what must never be banned.

**Repudiation.** Decisions record an origin (`CAPI`, `lists:<name>`), so a blocklist-derived ban
is identifiable and removable by origin. Within CAPI data there is no per-reporter attribution.

*Mitigations:* partially covered, and the origin field is the right design. Structural fix:
per-reporter attribution would let an operator distrust one source without distrusting the feed.

**Information disclosure.** Minimal — the engine receives addresses.

**Denial of service.** At startup LAPI must authenticate to CAPI unless a valid token is cached;
if that fails it does not start. An outage during a restart takes local protection down with it.

*Mitigations:* **GAP.** Quick win: comment out `online_client` on hosts that do not need CAPI,
which the documentation supports. Structural fix: treat a CAPI login failure at startup as
non-fatal. Trade-off: none apparent — local detection has no dependency on CAPI once running,
so the startup coupling looks like an oversight rather than a design choice.

**Elevation of privilege.** A compromised or coerced CAPI can ban arbitrary addresses across every
engine pulling the list.

*Mitigations:* allowlists, as above. Structural guardrail: require a local decision or a
consensus threshold before a remotely sourced ban takes effect on protected ranges.

### 4. Interaction: Enrollment and Telemetry, LAPI → Console

**Spoofing.** A compromised Console account acts on every enrolled engine at once.

*Mitigations:* the Console is the vendor's identity boundary; the engine cannot verify operator
intent. Quick win: enable MFA on the Console account and limit who holds it. Structural fix:
require local approval for Console-originated changes.

**Tampering.** Since v1.6.9 the engine accepts decision orders from the Console automatically
when the plan includes decision management. More seriously, a Console-pushed allowlist entry
makes an address skip AppSec entirely — in-band rules, hooks, challenge issuance, cookie
validation and out-of-band rules.

*Mitigations:* **GAP.** This is the highest-leverage crossing in the diagram: it can switch
detection off, not merely add bans. Quick win: audit Console-managed allowlists regularly.
Structural fix: require the allowlist bypass to be locally confirmed, or at minimum log it at
warning level rather than info.

**Repudiation.** The AppSec bypass is logged once at info level. Enrolment and telemetry are
not separately recorded.

*Mitigations:* **GAP.** Quick win: raise the allowlist-bypass log level.

**Information disclosure.** Enrolling turns on forwarding of manual decisions and tainted-scenario
alerts by default. The command prints that it has done so, but the default is on.

*Mitigations:* quick win: re-check `share_context` and `share_manual_decisions` after enrolling.
Structural fix: make enrolment preserve existing sharing settings.

**Denial of service.** Console unavailability does not stop local enforcement.

*Mitigations:* covered by design.

**Elevation of privilege.** Covered under tampering — the Console boundary can disable detection
for a chosen address.

## Design guardrails

- **Anchor detection content in something signed.** Every tampering and elevation finding on the
  hub crossing traces back to one missing property: nothing in the chain is signed. Hash checks
  against an unsigned index, and data files with no check at all, are the same gap at two levels.
  Signing the index closes the class; adding more hash checks does not.
- **Separate automation from authorization.** The daily timer is the availability mitigation and
  the integrity risk at once. Keeping the timer for fetching while gating the upgrade behind
  approval resolves the conflict instead of choosing a side.
- **Treat the Console as a trust boundary, not a management channel.** It can currently push bans
  and, through allowlists, switch off inspection for an address. Whatever controls apply to local
  administrative action should apply to it.
- **Make silent failure impossible.** A hash mismatch reported as staleness, a revocation check
  skipped when unconfigured, and a warning suppressed by `--error` are three instances of the same
  pattern. Controls that degrade quietly are worse than absent ones, because they report success.
- **Keep the local decision loop independent of the cloud.** Local detection does not need CAPI
  once running; the startup dependency is the only coupling and it removes protection at the worst
  moment.

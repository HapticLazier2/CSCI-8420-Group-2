# Trust-Boundary Review Checklist (Lead)

Run this on each DFD's draft PNG **before** the owner starts threat triage. Boundary mistakes change TMT's generated threat list, so fixing them later means redoing triage.

Record the result as a comment on the DFD's issue: **Signed off** or **Changes needed** with item numbers.

## A. Consistency across DFDs
- [ ] A1. Shared elements use the exact names in CONVENTIONS.md (`LAPI`, `CrowdSec DB`, `Bouncer`, …)
- [ ] A2. Shared elements have the same stencil type in every DFD (e.g. LAPI is always a Process)
- [ ] A3. Boundary names match the four standard boundaries
- [ ] A4. Where two DFDs share an interaction (e.g. LAPI↔DB in DFD-1 and DFD-2), it crosses the same boundaries in both

## B. Boundary placement
- [ ] B1. Every boundary marks a real change in trust: machine, network or privilege level
- [ ] B2. Internet-facing elements (CAPI, Console, Hub, Attacker) sit outside `Internet Boundary`
- [ ] B3. A bouncer or agent on another machine sits inside `Remote Host Boundary`, not on the LAPI host
- [ ] B4. `Config & Credentials` sits behind `Privilege Boundary` (root-only files)
- [ ] B5. The single-host default deployment and any distributed (multi-host) variant are either both modeled or the choice is stated

## C. Cross-boundary interactions (assignment emphasis)
For each flow crossing a boundary:
- [ ] C1. Direction is correct (who initiates: bouncers *pull* decisions from LAPI; agents *push* alerts)
- [ ] C2. Flow properties (Authenticates / Encrypted / Integrity) reflect the **default** config
- [ ] C3. Authentication material is visible: API key, JWT after machine login, TLS client cert, enrollment key
- [ ] C4. Return flows that carry security-relevant data are drawn (e.g. decisions back to bouncers, blocklist from CAPI)

## D. Completeness against scenarios
- [ ] D1. Each prioritized scenario from the earlier assignments is traceable to at least one flow
- [ ] D2. Level 2 detail is added only where it changes the threats (e.g. splitting the Agent into acquisition → parsers → scenarios)

## Sign-off log

| DFD | Owner | Reviewed on | Result | Notes |
|---|---|---|---|---|
| DFD-1 Detection | Kowshik | | | |
| DFD-2 Remediation | Mujib | | | |
| DFD-3 External | Trung | | | |

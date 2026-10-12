# Assurance Cases for Software Security Engineering

[Github Link](https://github.com/HapticLazier2/CSCI-8420-Group-2)

[ProjectBoard Link](https://github.com/users/HapticLazier2/projects/1)

CSCI-8420 Group 2 · System of interest: CrowdSec Security Engine (v1.8.x) · Environment: enterprise network (Multi-server LAPI)

## Top-Level Claim C2 — AppSec

**Contributor:** Kowshik

**Claim C2:** AppSec blocks known-malicious HTTP requests before they reach enterprise web applications, whatever the body framing or AppSec load.

**Attackers we worry about:** Remote Web Exploiter, WAF-Evasion Specialist

**Comes from:** UC-2 and requirements SR-2.1 to SR-2.4 in our last report

### C2 assurance case diagram

![C2 AppSec assurance case](resources/static/assurance/c2-appsec-assurance-case.png)

*Figure — Assurance case for claim C2. The editable file is `C2_AppSec_Assurance_Case.drawio`.*

How to read the diagram:

- White box = a claim (something we say is true).
- Yellow note = a doubt (a reason the claim could be false). It starts with "Unless".
- Blue note = a doubt about a piece of evidence.
- Circle = evidence (a real thing we can show, like a test result or a report).

### C2 narrative

AppSec is the guard at the door of our web applications. It is the only part of CrowdSec that looks at a request before the application gets it. If the guard misses a bad request, the application is on its own. That is why this claim is important.

The claim has two limits, shown in the context bubble (CT2). First, it is only about requests that our NGINX bouncers send to CrowdSec AppSec v1.8.x. Second, "known-malicious" means the request matches a rule that is turned on. Brand-new attacks that no rule knows about are not part of this claim.

We have a good reason to check this claim carefully (J2). Both ways to beat the guard have already happened in real life. A bug (CVE-2026-44982) let attackers hide a payload in the request body in versions 1.5.0 to 1.7.7. And by default, when AppSec is too slow, the bouncer lets the request through.

To build the argument, we asked one question again and again: "What could make this claim false?" Each answer is a doubt. For each doubt, we wrote a smaller claim that removes it. We found four main doubts.

1. **The request never goes through AppSec (R2.1).** Maybe there is a side door to the application. Our answer (C2.1): every network path to the applications goes through a bouncer with AppSec turned on. We show this with a review of the reverse-proxy settings and a network scan that looks for side doors.
2. **The rules do not catch the attack (R2.2).** Our answer (C2.2): the rules that are turned on stop known SQL injection, XSS and CVE attacks. Two smaller doubts are left. The rules may only write a log and not block (in CrowdSec, the CRS rules are optional and only watch when you add them). Or the rules may be old. We remove these with attack test results, a list of the blocking rules, update logs and a version check.
3. **The attack hides in the request body (R2.3).** This is the first trick of the WAF-Evasion Specialist. The body can get lost in two places, so we split the doubt in two. The AppSec engine may skip the body (C2.3.1), or the bouncer may send the request without the body (C2.3.2). The tests for each body type are the most important evidence here. So we also doubted the tests themselves (the blue note UM2.3.1): "What if the tests ran on a different version than the one we use?" A list of the test build and settings removes that doubt.
4. **AppSec is too busy and lets requests through (R2.4).** This is the second trick of the WAF-Evasion Specialist. Our answer has two parts. Every bouncer must say "no" when AppSec is slow or broken (C2.4.1). And if a request still gets through without a check, the SOC team must get an alert (C2.4.2).

Every branch ends in evidence that a reviewer can ask to see. In total, the diagram has ten yellow doubts, one blue doubt and thirteen pieces of evidence. If we collect all thirteen, no doubt that we found is left open. Today, most of this evidence does not exist yet. The next table shows what is missing.

### C2 evidence alignment and gaps (Part 2)

We sorted each piece of evidence into one of four groups:

- **Easy to get** = CrowdSec already gives us a command or a file for it.
- **Partly there** = some of it exists in the project, but not all.
- **Our own work** = our company must make it; the CrowdSec project cannot.
- **Gap** = the CrowdSec project should have it, but it does not.

| Evidence | Group | What we found |
| --- | --- | --- |
| E2.1.1 Reverse-proxy configuration audit report | Our own work | Only our company knows how its network is set up. |
| E2.1.2 Network scan results for direct paths to application origins | Our own work | Our network team must run this scan. |
| E2.2.1 Attack-payload regression test results | Partly there | The CrowdSec Hub tests its AppSec rules on every pull request. We still need to run the tests on our own setup. |
| E2.2.2 In-band rule inventory for each AppSec configuration | Easy to get | We can read it from the AppSec config files. **Gap:** CRS rules are not in the default setup, and when added they only watch and do not block. |
| E2.2.3 Hub upgrade job logs | Easy to get | We need a scheduled job that runs `cscli hub update` and `cscli hub upgrade` and saves the output. |
| E2.2.4 Installed-versus-Hub rule version comparison report | Easy to get | `cscli hub list` shows if each item is up to date. |
| E2.3.1 Negative test results for each body framing | **Gap** | The bug was fixed in v1.7.8, but v1.8.1 has no test for chunked or HTTP/2 bodies. |
| E2.3.2 Build and configuration manifest of the test environment | Easy to get | `cscli version` plus our config files in version control. |
| E2.3.3 Unreadable-body test results for HTTP/2 and HTTP/3 | **Gap** | We found no such tests. We would have to write them. |
| E2.3.4 Bouncer configuration baseline | Easy to get | **Gap in defaults:** `APPSEC_DROP_UNREADABLE_BODY` is off, so the bouncer sends these requests without the body. |
| E2.4.1 Fault-injection and peak-load test results | Our own work | We must run these tests in our own network, at our own busiest traffic level. |
| E2.4.2 Failure-action and timeout configuration audit report | Easy to get | Timeouts are set by default (100 ms, 100 ms, 500 ms). **Gap in defaults:** `APPSEC_FAILURE_ACTION` is `passthrough`, which lets requests through. |
| E2.4.3 Fail-open alert test records from the SIEM | **Gap** | Timeouts and errors are logged as errors. But a request sent without its body is logged only at debug level, so nobody sees it. We need a log change and a SIEM alert rule. |

**Summary:** Out of 13 pieces of evidence, 6 are easy to get, 1 is partly there, 3 need our own work, and 3 are gaps in the CrowdSec project. Nothing is ready to use on day one. The biggest gaps are the missing body tests and the quiet logging when a request is sent without its body.

## Reflection on the AI prompt's usefulness

### C2 — AppSec (Kowshik)

We used Claude (Anthropic) with both of the instructor's prompts.

#### Prompt 1: claim wording

```text
You are an expert software security engineer. Your job is to suggest corrections or
improvements in the phrasing of assurance claims. Claims concern critical properties that
are risk-related. High confidence is needed in their realization. A claim is always worded
with a predicate. Avoid claims about the supporting method/techniques.
Bad claim: "The system uses AES encryption." Why? Because it is not interesting; just the
technology is just a means to an end, but does not provide assurance that it can actually
keep the information confidential.
Claim should be a reasonable goal (outcome). Good claim: "The system minimizes information
disclosure during communication"
Good Claim Checklist: 1. Includes an entity relevant to the argument, 2. a critical property
of the entity, 3. a value for the property and related uncertainty.
Use this statement as a potential claim for analysis. Explain why or why not this statement
is a good claim.
"""
AppSec enforces timeouts and a fail-closed failure action
"""
```

Before and after:

| | Statement | Why |
| --- | --- | --- |
| Before | AppSec enforces timeouts and a fail-closed failure action | It talks about the tool, not the result. It says two things at once. It also names the wrong part: the bouncer does this, not AppSec. |
| After | Every production bouncer denies requests when AppSec times out or returns an error (C2.4.1) | It names one thing (the bouncers), one property (what happens to an unchecked request) and one value (denied, on every bouncer). |

#### Prompt 2: rebuttals

```text
You are an expert software security engineer. Your job is to suggest rebutting defeater for
a given assurance claim using the concept of eliminative induction where support/assurance
increases as reasons for doubt are eliminated. Here is an example claim for which rebutting
defeaters are identified.
Claim: The bulb will glow when switched on
Rebuttal 1: Unless switch not connected to light
Rebuttal 2: Unless no power
Rebuttal 3: Unless dead light bulb
Use this statement as a potential claim for analysis. Keep the rebuttals short and intuitive
for including in a readable diagram.
"""
AppSec blocks known-malicious HTTP requests before they reach enterprise web applications,
whatever the body framing or AppSec load
"""
```

The AI gave 11 rebuttals. We compared them with the ten rebuttals in our diagram.

| # | AI rebuttal | In our diagram? |
| --- | --- | --- |
| 1 | Unless the request bypasses AppSec | Yes, R2.1 |
| 2 | Unless no rule matches the payload | Yes, R2.2 |
| 3 | Unless rules only detect and do not block | Yes, R2.2.1 |
| 4 | Unless the rules are outdated | Yes, R2.2.2 |
| 5 | Unless the body is not inspected (chunked or HTTP/2) | Yes, R2.3 and R2.3.1 |
| 6 | Unless AppSec times out and the request is let through | Yes, R2.4.1 |
| 7 | Unless AppSec is down | Yes, R2.4 |
| 8 | Unless the payload is encoded or obfuscated | No. We treat it as part of R2.2. The attack tests (E2.2.1) should include encoded payloads. |
| 9 | Unless the body is bigger than the inspection limit | No. It is a fair doubt. We left it out to keep the diagram readable. |
| 10 | Unless the source IP is on an allowlist | No. It is a fair doubt. We left it out to keep the diagram readable. |
| 11 | Unless the attack is a zero-day | No. It is outside our claim. The context (CT2) says the claim is only about attacks that a rule already knows. |

What the comparison showed:

- **7 of the 11 AI rebuttals match ours.** They cover 8 of our 10 rebuttals. This told us our main doubts are the right ones.
- **The AI missed 2 of ours.** These are R2.3.2 (the bouncer sends a request without its body) and R2.4.2 (an unchecked request passes and nobody notices). The AI could not know these. We found them by reading the CrowdSec source code in the last assignment.
- **The AI gave 4 that we do not have.** One was wrong for our claim (zero-day). One is already covered by our evidence (encoded payload). Two are fair and are leftover doubts for future work (big body, allowlisted IP).

#### What we think about the AI prompts

The AI was a good helper for two jobs. It fixed the wording of our claims, so they talk about results and not about tools. It also gave a fast list of doubts, which let us check that we did not forget a big one.

The AI was weak in three ways. It only knows general WAF problems, so it missed the two doubts that are special to CrowdSec. It gave a doubt that was outside our claim (zero-day), because it did not pay attention to our context. And in the first draft, it wrote two claims that said almost the same thing (C2.4 and C2.4.1), so one had to be reworded.

Our lesson: the AI is good for a first list, but we must check every item against our own claim, our context and the real CrowdSec code.

## References

- CrowdSec AppSec general setup — <https://docs.crowdsec.net/docs/appsec/quickstart/general_setup>
- CVE-2026-44982 advisory (GHSA-rw47-hm26-6wr7) — <https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-rw47-hm26-6wr7>
- NGINX bouncer AppSec options — <https://docs.crowdsec.net/u/bouncers/nginx>

## Team Reflections

### Kowshik's Reflection

In this assignment I built the assurance case for claim C2 about AppSec. I learned that a good claim talks about a result, not about a tool. I also learned that evidence must be a thing you can show, like a test result or a report, and not another claim.

The most useful part for me was the "Unless" question. Each time I asked "what could make this false?", I found a new doubt, and each doubt needed its own answer and its own evidence. Doing this showed me that CrowdSec has the right features for AppSec, but most of the proof is missing. For example, there are no tests for chunked or HTTP/2 bodies, and the default setting lets requests through when AppSec is slow.

I also learned to use AI with care. It helped me with wording and with a first list of doubts. But it missed the doubts that are special to CrowdSec, and it gave some that did not fit our claim. So I checked each one against our last report before I kept it.

### Trung's Reflection

### Leonard's Reflection

### Mujib's Reflection

### Hrudhay's Reflection

# Threat Modeling Conventions — Group 2 (CrowdSec)

Everyone follows these so the three DFDs can be compared, merged and graded as one model.

## 1. Tool and template

- **Microsoft Threat Modeling Tool**, latest version (Windows or a Windows VM).
- **Template:** `SDL TM Knowledge Base (Core)`. Do **not** use the Azure template; CrowdSec isn't an Azure system and the threat lists won't be comparable.
- One `.tm7` file per DFD. **Only the DFD owner commits that file.** `.tm7` is XML that Git can't merge.
- Fill the model's **Owner**, **Reviewer** and **Contributors** fields (Settings → Threat Model Information). They appear in the HTML report.

## 2. Repository layout

```
threat-model/
  CONVENTIONS.md
  BOUNDARY-REVIEW.md
  dfd1-detection/dfd1-detection.tm7      (Kowshik)
  dfd2-remediation/dfd2-remediation.tm7  (Mujib)
  dfd3-external/dfd3-external.tm7       (Trung)
  images/dfd1.png, dfd2.png, dfd3.png    (owners)
  reports/dfd1.htm, dfd2.htm, dfd3.htm   (Leonard only)
  ai/                                    (Hrudhay)
ThreatModeling.md                        (submission, Leonard assembles)
```

## 3. Element names

Use **exactly** these names whenever an element appears in more than one DFD. Prefix elements unique to your DFD with your DFD number.

| Element | TMT stencil | Notes |
|---|---|---|
| `LAPI` | Process | Local API server |
| `Security Engine (Agent)` | Process | Acquisition + parsers + scenarios |
| `CrowdSec DB` | Data Store (SQL) | SQLite by default; note if modeling MySQL/PostgreSQL |
| `Config & Credentials` | Data Store (File) | config.yaml, credentials files, API keys |
| `Log Files` | Data Store (File) | Logs the agent reads |
| `Bouncer` | Process | Remediation component |
| `Protected Service` | External Interactor | e.g. nginx/SSH; produces logs, enforced by bouncer |
| `Administrator` | External Interactor (Human) | Uses `cscli` |
| `cscli` | Process | Admin CLI |
| `CAPI` | External Interactor | CrowdSec Central API |
| `CrowdSec Console` | External Interactor | Web console |
| `CrowdSec Hub` | External Interactor | Parser/scenario/collection source |
| `Attacker / Client` | External Interactor (Human) | Source of traffic producing log lines |

**Data flows:** name them as *payload (protocol)*, for example `Alerts (HTTPS POST)`, `Decisions (HTTP/S GET stream)`, `Log lines (file read)`. If a flow can be HTTP **or** HTTPS depending on config, say so in the name. That ambiguity is a finding.

## 4. Trust boundaries

Use the same boundary names everywhere:

| Boundary | Separates |
|---|---|
| `Internet Boundary` | Anything on the public internet (CAPI, Console, Hub, attackers) from the deployment |
| `LAPI Host Boundary` | The machine running LAPI and its DB from everything else |
| `Remote Host Boundary` | A bouncer or agent on a different machine from LAPI |
| `Privilege Boundary` | Root/admin-only resources (credentials, `cscli`) from unprivileged processes |

Draw a boundary only where **trust actually changes**: a different machine, network or privilege level. Don't draw one just to make the diagram look organized.

## 5. Element properties

TMT generates threats from element properties, so set them deliberately:

- On every data flow crossing a boundary, set **Authenticates** / **Encrypted** / **Provides Integrity** to match CrowdSec's **default** configuration. Put the hardened option in the mitigation, not the property.
- Note any property you weren't sure about in the element's description field.

## 6. Threat triage format

For **every** generated threat in your final diagram:

| TMT field | What to write |
|---|---|
| **State** | `Mitigated`, `Not Applicable` or `Needs Investigation`. Don't leave any as `Not Started`. |
| **Priority** | High / Medium / Low (likelihood × impact, your judgment) |
| **Justification** | One to three sentences. For *Not Applicable*: why it can't happen here. For *Mitigated*: the mitigation and where it lives (code, config, deployment). |

In the Justification, start cross-boundary threats with `[XB]` so they're easy to pull out of the report.

### Mitigation entries for ThreatModeling.md

| ID | Threat (STRIDE) | Element / flow | XB? | Mitigation | Layer (code / config / deployment / process) | Quick win or structural |
|---|---|---|---|---|---|---|

The **Mitigation** column describes the expected control. Part 2 then checks whether CrowdSec actually has it.

## 7. Part 2 observation format

| Mitigation ID | Expected control | Status | Evidence | Gap / notes |
|---|---|---|---|---|
| D2-07 | Bouncer–LAPI traffic is TLS-protected | Partial | link to docs/config line | TLS optional; default local setup is HTTP |

Status is one of `Present`, `Partial` or `Absent`. Evidence must be a link: a GitHub permalink to a file/line, or a docs URL.

## 8. Workflow

1. Draft the Level 1 diagram, export a PNG, and request boundary review on your issue.
2. Once the boundaries are signed off, refine the diagram and triage threats.
3. Export the HTML report (Reports → Create Full Report) and hand it to Leonard.
4. Do the Part 2 code check and send the table to Hrudhay.

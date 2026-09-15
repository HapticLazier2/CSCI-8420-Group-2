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

[home / office / enterprise / bank / government — 
describe the setting and why users there would deploy this software]

### Systems engineering diagram

[Embed diagram image here, e.g. ![systems diagram]
(diagrams/systems-view.png). Diagram should show the software's components, 
the actors/users involved, adjacent systems it interacts with, network zones, 
and trust boundaries within the chosen environment.]

## 3. Security Needs, Threats, and Features

(Issue #4)

### Threats perceived by users

[List realistic threats a user in 
this environment would worry about
who the likely attacker is, what 
they're after, and the attack surface.]

### Security features in the software

[List the software's actual security 
features that address the threats above.]

Threat → Feature mapping
Threat	Addressed by
[threat]	[feature]
[threat]	[feature]

## 4. Team Motivation

(Issue #5)

[Why the team chose this project
tie it to team skills/interests 
(networking background, Go learning goal,
research interest) and to what's genuinely 
useful or interesting about the software itself.]

## 5. Open-Source Project Description

### What it is Leonard

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

(Issue #8)

[3–5 notable CVEs or security advisories: what the vulnerability was, severity, how/when it was fixed. Plus any notable security-driven design decisions — features added, removed, or hardened for security reasons.]

## 8. Reflection

(Issue #9)

### Individual reflections (what did you learn from this assignment? what did you find most useful?)

Mujib: [reflection]
Kowshik: [reflection]
Leonard: [reflection]
Trung: [reflection]
Hrudhay: [reflection]

### Team reflection (compiled)

[Synthesized summary of the above — not just a list of quotes.]

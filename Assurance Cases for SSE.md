# Assurance Cases for Software Security Engineering

[Github Link](https://github.com/HapticLazier2/CSCI-8420-Group-2)

[ProjectBoard Link](https://github.com/users/HapticLazier2/projects/1)

CSCI-8420 Group 2 · System of interest: CrowdSec Security Engine (v1.8.x) · Environment: enterprise network (Multi-server LAPI)

## C4: Changes to detection content and policy are authorized, attributable to an individual, and cannot silently disable detection

Contributor: Trung Phan 

![Manage Policy & Detection Content](resources\static\assurance\UC4_Assurance_Case.png)
<p align="center">Manage Policy & Detection Content</p>

### Top Claim and Context

Top claim C1 says that changes to detection content and policy are authorized, attributable to an individual, and cannot silently disable detection. Three context nodes frame it. CT1 names the system, the CrowdSec Security Engine v1.8.1 with a multi-server local API. CT2 names the two misusers, a Malicious Hub Contributor and an Insider SOC Analyst. CT3 names the requirements SR-4.1 to SR-4.5 and notes that SR-4.3 and SR-4.4 are gaps. The inference rule IR1 connects C1 to its sub-claims. It states that if all three hold, the top claim holds.

### SC1: Changes Are Authorized (SR-4.1, SR-4.2, SR-4.4)

This sub-claim has three rebuttals. R1 asks whether a poisoned scenario from a Malicious Hub Contributor could merge past Hub CI. E1 answers it with Hub CI test results and maintainer review records, although no written review policy was found. R2 asks whether a locally altered Hub item could be silently overwritten on upgrade. E2 answers it with upgrade test results showing that a modified item is flagged and is not overwritten without an explicit override. R3 asks whether a read-only analyst could run `cscli` with full administrator rights. E3 does not rebut it: the documentation and configuration review shows there is no role separation, so the doubt stands. Because one defeater stands, SC1 is not supported as a whole.

### SC2: Changes Are Attributable to an Individual (SR-4.3)

This sub-claim has two rebuttals, and both stand. R4 asks whether an insider could allowlist an accomplice's IP address with nothing naming them. E4 confirms this, since the source and documentation review found no audit trail for allowlist changes. R5 asks whether manual decisions or machine and bouncer deletions can be traced to a person. E5 confirms they cannot, because the test results show no operator identity recorded. SC2 is therefore not supported, and it is the clearest gap in the case.

### SC3: A Change Cannot Silently Disable Detection (SR-4.5)

This sub-claim has three rebuttals, and this is where the existing controls work. R6 asks whether a broken configuration could be activated and blind detection. E6 answers it with validation test results showing that an invalid configuration is rejected before activation. R7 asks whether a new scenario could issue live decisions before anyone has tested it. E7 answers it with simulation test results showing the scenario fires but issues no live decision. R8 asks whether a valid allowlist or configuration could blind detection without anyone noticing. E8 only partly answers it. The log review shows every suppression is recorded, so the effect is visible, but the record does not say who made the change. SC3 is therefore partly supported.

### Usefulness of AI Promp
 
"You are a security software engineer, and you need some ideas on what are the sub claims that could counter the top claim "Changes to detection content and policy are authorized, attributable to an individual, and cannot silently disable detection", include misuse case and rebuttals as well"

I think this promp has helped me a lot because it give the foundation for my top claim that I could start with and also Claude also explain on why it choose it. From there, I start my research with its claim and make adjustment if needed. 

### References

#### Kowshik's Reflection

#### Trung's Reflection

#### Leonard's Reflection

#### Mujib's Reflection


#### Hrudhay's Reflection

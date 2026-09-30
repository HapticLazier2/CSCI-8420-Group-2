## Security Documentation Review

### Scope and method

We reviewed CrowdSec's security-related **installation** and **configuration** documentation for the release our analysis targets (v1.8). We read the documentation source directly rather than the rendered pages, so every quote below is exact. The sources were:

- the [`crowdsec-docs`](https://github.com/crowdsecurity/crowdsec-docs) repository at commit [`bad5aa9`](https://github.com/crowdsecurity/crowdsec-docs/tree/bad5aa9) (25 September 2026). The published `/docs/` pages come from `versioned_docs/version-v1.8`, and the `/u/` pages from `unversioned/`.
- the Docker image README in the engine repository.
- `SECURITY.md`.

Wherever the documentation states a default or a behavior, we checked it against the code:

- the engine at tag [`v1.8.1`](https://github.com/crowdsecurity/crowdsec/tree/v1.8.1)
- the NGINX/OpenResty bouncer library [`lua-cs-bouncer@ec94d51`](https://github.com/crowdsecurity/lua-cs-bouncer/tree/ec94d51)
- the Windows firewall bouncer [`cs-windows-firewall-bouncer@36d3065`](https://github.com/crowdsecurity/cs-windows-firewall-bouncer/tree/36d3065)

For each finding we ask one question: **would an administrator who follows the documentation exactly end up with a deployment that one of our misusers can exploit?** The misusers are the ones from our misuse case catalog.

| Severity | Meaning |
|---|---|
| **High** | Following the documentation as written leaves the deployment open to a misuser from our catalog, or the documentation states the opposite of what the code does on a security control. |
| **Medium** | A real risk that the documentation leaves out or describes incompletely. A careful reader could still avoid it. |
| **Low** | Hygiene, accuracy or maintenance problems with limited direct impact. |

| Type | Meaning |
|---|---|
| **Wrong** | The documentation contradicts the code, or contradicts itself. |
| **Unsafe advice** | The documentation recommends an insecure setting or practice. |
| **Missing** | A security-relevant behavior, default or option is not documented. |

### Summary of findings

| ID | Area | Finding | Severity | Type | Misuser it enables |
|---|---|---|---|---|---|
| DR-1 | LAPI transport | Docs say TLS is unnecessary on a LAN or VPN | High | Unsafe advice | Network-Positioned Interceptor |
| DR-2 | LAPI transport | Docs say self-signed certificates **require** `insecure_skip_verify`; in code that flag also reaches the CAPI client | High | Wrong / Unsafe advice | Network-Positioned Interceptor, Upstream Traffic Interceptor |
| DR-3 | mTLS revocation | Revocation docs are wrong in both directions: CRL handling is stricter than documented, OCSP handling is looser | High | Wrong | Bouncer-Key Thief, Rogue-Agent Registrant |
| DR-4 | LAPI behind a proxy | `trusted_proxies` is undocumented, and when omitted it trusts every client's `X-Forwarded-For` | High | Missing | Rogue-Agent Registrant |
| DR-5 | NGINX bouncer | The page contradicts itself on the `SSL_VERIFY` default, and understates what the setting controls | High | Wrong | Network-Positioned Interceptor |
| DR-6 | NGINX bouncer / AppSec | `APPSEC_FAILURE_ACTION` covers far more than "a 500", so the WAF silently fails open by default | Medium | Wrong / Missing | WAF-Evasion Specialist |
| DR-7 | LAPI authorization | `trusted_ips` is described as "admin access", but it guards only alert deletion | Medium | Wrong | Rogue-Agent Registrant, Insider SOC Analyst |
| DR-8 | Credentials | Shared bouncer keys, placeholder tokens, and almost no file-permission guidance | Medium | Unsafe advice / Missing | Bouncer-Key Thief |
| DR-9 | Metrics / debug | pprof is unauthenticated, can't be disabled on its own, and opening port 6060 for Prometheus exposes it | Medium | Missing | Pre-Auth LAPI Flooder |
| DR-10 | Log datasources | Kubernetes-audit has no authentication or TLS and no warning; no default read timeouts | Medium | Missing | Log-Forging Outsider, Credentialed Log-Pusher |
| DR-11 | Docker | Image README publishes LAPI and pprof on all interfaces; container runs as root; the "Docker secrets" tip only partly works | Medium | Unsafe advice / Missing | Pre-Auth LAPI Flooder |
| DR-12 | Kubernetes / Helm | Auto-registration allows all private ranges; the Secrets example is invalid; the install page never mentions TLS | Medium | Unsafe advice / Wrong | Rogue-Agent Registrant |
| DR-13 | Linux packages | APT pin gives the third-party repo priority 1001 over **every** package | Medium | Unsafe advice | (supply chain) |
| DR-14 | Notifications | Splunk plugin never verifies TLS, and the docs don't say so | Medium | Missing | Network-Positioned Interceptor |
| DR-15 | Data sharing | No page lists what is shared with CrowdSec by default | Medium | Missing | Signal-Data Harvester |
| DR-16 | Linux / Windows install | `curl \| sudo sh` is the headline method; no key fingerprints; legacy key path; Windows page requires end-of-life .NET 6 | Low | Unsafe advice / Wrong | — |
| DR-17 | Security policy | No supported-versions table, no response timeline, no advisory index in the docs | Low | Missing | — |
| DR-18 | Docs maintenance | No hardening guide; 165 links from released pages point to unreleased `/docs/next/` pages | Low | Missing | — |

Five findings are rated High. In four of them (DR-1, DR-2, DR-3, DR-5) the documentation and the code disagree about a TLS control, or the documentation tells the reader to weaken one. The fifth (DR-4) is an undocumented default that lets any client choose the IP address LAPI sees.

---

### A. Local API transport and authentication

#### DR-1 — "TLS is not necessary on a LAN" (High, unsafe advice)

- **What the docs say.** The [Local API configuration page](https://docs.crowdsec.net/docs/local_api/configuration) says: *"If your Log Processors and Remediation Components are part of the same LAN or VPN, this step is not necessary"* ([source L89](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/local_api/configuration.md#L89)). The [multi-server guide](https://docs.crowdsec.net/u/user_guides/multiserver_setup/) then has readers set `listen_uri: 0.0.0.0:8080` over plain HTTP. It mentions TLS only as a way to avoid validating machines, not as protection for traffic ([L37, L47–50](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/user_guides/multiserver_setup.md#L37-L50)).
- **Why it matters.** On a flat enterprise LAN, bouncer API keys, machine passwords, JWTs and every decision cross the network in cleartext. That is exactly the position our **Network-Positioned Interceptor** needs, and it undoes SR-3.4.
- **Fix.** Delete the sentence. Make TLS the default in the multi-server guide, and state plainly what travels in cleartext without it.

#### DR-2 — `insecure_skip_verify` is presented as required, and its reach is undocumented (High, wrong / unsafe advice)

- **What the docs say.** The same page says: *"If you are using a self signed certificate … you must enable `insecure_skip_verify` options"*, and shows `insecure_skip_verify: true` ([L104–113](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/local_api/configuration.md#L104-L113)). The [configuration reference](https://docs.crowdsec.net/docs/configuration/crowdsec_configuration) describes the option only as *"Allows the use of https with self-signed certificates"* ([L934](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/configuration/crowdsec_configuration.md#L934)).
- **What the code does.**
  - Skip-verify isn't needed. The client already accepts a `ca_cert_path` and adds that CA to the system trust pool ([api.go L196–212](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/api.go#L196-L212)).
  - `api.client.insecure_skip_verify` is copied into a **package-level** variable, `apiclient.InsecureSkipVerify` ([api.go L190–194](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/api.go#L190-L194)). Every client built by that package reads the variable ([client.go L188](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiclient/client.go#L188)), and that includes the Central API client LAPI creates ([apic.go L232](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/apic.go#L232)).
  - So on a host that runs both the agent and LAPI, which is the default install, following the docs would also turn off certificate checks toward `api.crowdsec.net`. We found this by reading the code and have not tested it.
- **Related.** The [Kafka datasource](https://docs.crowdsec.net/docs/log_processor/data_sources/kafka) examples set `insecure_skip_verify: true` right next to a `ca_cert`, which makes the CA pointless ([L30](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/log_processor/data_sources/kafka.md#L30)).
- **Fix.** Replace the advice with a `ca_cert_path` example, and document that the flag's scope reaches CAPI. Separately, report the shared global to the maintainers (see "Contributing back").

#### DR-3 — Certificate revocation is documented wrong in both directions (High, wrong)

The [TLS authentication page](https://docs.crowdsec.net/docs/local_api/tls_auth) ([L29–31, L43](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/local_api/tls_auth.md#L29-L43)) and the v1.8.1 code disagree:

| Situation | Documentation says | v1.8.1 code does |
|---|---|---|
| CRL file has expired | Check is skipped | Still checks against it and logs a warning ([crl.go L128–130](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/crl.go#L128-L130)) |
| CRL file invalid at startup | Check is skipped | LAPI refuses to start ([crl.go L31–34](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/crl.go#L31-L34)) |
| CRL file becomes invalid later | Check is skipped | Keeps using the last good CRL ([crl.go L112–116](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/crl.go#L112-L116)) |
| OCSP server unreachable, times out, or answers "unknown" | *(not mentioned — docs cover only a "malformed response")* | **Certificate is accepted.** The log says *"assuming the cert is revoked"*, but the function reports the check as not performed, and the caller rejects only checks that were performed ([ocsp.go L98–100](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/ocsp.go#L98-L100), [tls_auth.go L54](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/middlewares/v1/tls_auth.go#L54)) |
| No `crl_path` configured | Check is skipped | Check is skipped (matches) |

- **Why it matters.** The documentation warns about a failure that no longer exists and misses the one that does. A stolen client certificate that has been revoked through OCSP is still accepted whenever the OCSP responder can't be reached, and the log line tells the operator the opposite.
- **Fix.** Rewrite the "Revocation checking" section from the code. Add a warning that OCSP fails open and that CRL checking happens only when `crl_path` is set. Separately, report the misleading log line.

#### DR-4 — `trusted_proxies` is undocumented and trusts everyone by default (High, missing)

- **What the docs say.** The configuration reference documents `use_forwarded_for_headers` with one warning: *"Do not enable if you are not running the LAPI behind a trusted reverse-proxy or LB"* ([L1073](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/configuration/crowdsec_configuration.md#L1073)). `trusted_proxies` has no entry at all in the reference. It appears only in one example on the LAPI configuration page.
- **What the code does.** If `use_forwarded_for_headers` is `true` and `trusted_proxies` is left out, LAPI sets `trusted_proxies` to `0.0.0.0/0` ([api.go L417–419](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/api.go#L417-L419)). Every client may then choose its own `X-Forwarded-For`. That header feeds the IP used for:
  - the `trusted_ips` check, where `127.0.0.1` is always trusted ([alerts.go L343–346](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/v1/alerts.go#L343-L346)).
  - the auto-registration `allowed_ranges` check ([machines.go L21](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/v1/machines.go#L21)).

  A token or a login is still required, so what's lost is the network restriction that is supposed to back up those credentials. This comes from reading the code; we have not tested it.
- **Fix.** Document `trusted_proxies`, its default, and that leaving it out trusts every source. Recommend always listing the proxy address explicitly.

#### DR-5 — NGINX bouncer: `SSL_VERIFY` contradicts itself and does more than the docs say (High, wrong)

- **What the docs say.** The [NGINX bouncer page](https://docs.crowdsec.net/u/bouncers/nginx) gives `SSL_VERIFY=true  # default` in two configuration listings ([L204](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/bouncers/nginx.mdx#L204), [L298](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/bouncers/nginx.mdx#L298)). The parameter reference on the same page says `SSL_VERIFY=false  # default` and describes it only as *"Verify the AppSec Component SSL certificate validity"* ([L682–685](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/bouncers/nginx.mdx#L682-L685)).
- **What the code does.**
  - The default is `"true"` ([config.lua L27](https://github.com/crowdsecurity/lua-cs-bouncer/blob/ec94d51/lib/plugins/crowdsec/config.lua#L27)).
  - The same setting also controls certificate checks on every **LAPI** call: decision pulls, stream and metrics ([crowdsec.lua L333](https://github.com/crowdsecurity/lua-cs-bouncer/blob/ec94d51/lib/crowdsec.lua#L333), [L454](https://github.com/crowdsecurity/lua-cs-bouncer/blob/ec94d51/lib/crowdsec.lua#L454), [L700](https://github.com/crowdsecurity/lua-cs-bouncer/blob/ec94d51/lib/crowdsec.lua#L700)).
- **Why it matters.** An administrator who switches it off "just for AppSec" also sends the bouncer API key to LAPI without checking who is on the other end.
- **Also wrong on the page.** `APPSEC_PROCESS_TIMEOUT` is documented as `1000`; the code default is `500` ([config.lua L25](https://github.com/crowdsecurity/lua-cs-bouncer/blob/ec94d51/lib/plugins/crowdsec/config.lua#L25)).
- **Fix.** Correct both defaults, and say that `SSL_VERIFY` covers both LAPI and AppSec.

### B. AppSec, authorization and credentials

#### DR-6 — `APPSEC_FAILURE_ACTION` covers far more than "a 500" (Medium, wrong / missing)

- **What the docs say.** The bouncer page says the setting applies *"when the AppSec Component returns a 500"* ([L665](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/bouncers/nginx.mdx#L665)). The [AppSec protocol page](https://docs.crowdsec.net/docs/appsec/protocol) says the same ([L105](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/appsec/protocol.md#L105)).
- **What the code does.** The fallback is applied to:
  - connection errors and timeouts ([crowdsec.lua L707–712](https://github.com/crowdsecurity/lua-cs-bouncer/blob/ec94d51/lib/crowdsec.lua#L707-L712)).
  - a **401**, which is what a revoked or wrong API key produces ([L737](https://github.com/crowdsecurity/lua-cs-bouncer/blob/ec94d51/lib/crowdsec.lua#L737)).
  - any other unexpected status.

  With the default `passthrough`, revoking the bouncer's key or knocking AppSec over silently turns the WAF off. The only trace is an error-level log line.
- **Possible bypass (not tested).** The [AppSec hooks page](https://docs.crowdsec.net/docs/appsec/hooks) says oversized bodies are dropped by default ([L276](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/appsec/hooks.md#L276)). But the bouncer's own code comment says that on a body over the limit, AppSec closes the connection while the bouncer is still sending, so the bouncer takes the error path ([crowdsec.lua L708–709](https://github.com/crowdsecurity/lua-cs-bouncer/blob/ec94d51/lib/crowdsec.lua#L708-L709)). With `passthrough`, an oversized request may therefore reach the application without inspection. This is exactly what our **WAF-Evasion Specialist** would try, and it needs testing.
- **Fix.** Document every case that triggers the fallback. Add a "recommended for production" block (`APPSEC_FAILURE_ACTION=deny`, `APPSEC_DROP_UNREADABLE_BODY=true`), and link the engine's body-size behavior to the bouncer's failure behavior.

#### DR-7 — `trusted_ips` promises more than it delivers (Medium, wrong)

- **What the docs say.** `trusted_ips` is documented as the *"IPs or IP ranges which have admin access to API"* ([L1196](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/configuration/crowdsec_configuration.md#L1196)).
- **What the code does.** It guards only the two alert-deletion routes. Both decision-deletion routes are open to **any** validated machine, from any address ([controller.go L132–133](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/controller.go#L132-L133), [decisions.go L134](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/apiserver/controllers/v1/decisions.go#L134)).
- **Why it matters.** An operator who narrows `trusted_ips` believes they have limited who can remove bans. They have not.
- **Fix.** List exactly which routes `trusted_ips` protects.

#### DR-8 — Credential hygiene (Medium, unsafe advice / missing)

- **Shared keys.** The multi-server guide advertises that *"multiple remediation components running on different machines can use the same API key"* ([L142](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/user_guides/multiserver_setup.md#L142)). It doesn't mention the cost: one leaked key can't be revoked without breaking every bouncer that uses it, and LAPI can no longer tell which host pulled what. This works against SR-3.1 and SR-3.3.
- **Placeholder token.** The auto-registration token example is the literal string `long_token_that_is_at_least_32_characters_long` ([L61](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/user_guides/multiserver_setup.md#L61)), with no generation command. The bot-detection page already shows the right pattern, `openssl rand -hex 32` ([L64](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/appsec/bot_detection/configuration.md#L64)).
- **File permissions.** No page says how to protect `local_api_credentials.yaml` or the bouncer configuration files that hold API keys. The only exception is the HAProxy SPOA page, which does it well ([L1488–1495](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/bouncers/haproxy_spoa.mdx#L1488-L1495)).
- **Log permissions.** The troubleshooting page fixes log-read errors with `sudo chmod 644 /var/log/nginx/access.log`, which makes the web logs world-readable ([L98](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/troubleshooting/issue_lp_no_logs_read.md#L98)).
- **Fix.** Recommend one key per bouncer. Add a token-generation command. Reuse the HAProxy permissions block on the other bouncer pages. Replace `chmod 644` with adding the crowdsec user to the log group.

### C. Exposed services

#### DR-9 — pprof is documented, but its risk is not (Medium, missing)

- **What the docs say.**
  - The [network management page](https://docs.crowdsec.net/docs/configuration/network_management) lists pprof on `tcp/6060` ([L11](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/configuration/network_management.md#L11)). The same page tells readers to *"allow inbound connections to `tcp/6060`"* for Prometheus scraping ([L57](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/configuration/network_management.md#L57)).
  - The [Prometheus page](https://docs.crowdsec.net/docs/observability/prometheus) suggests editing `listen_addr` for external scraping.
  - Neither page says that pprof is unauthenticated, or that opening the port for metrics also opens `/debug/pprof`.
- **What the code does.** pprof is always registered on the same server as the metrics ([main.go L7](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec/main.go#L7), [metrics.go L92–94](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/crowdsec/metrics.go#L92-L94)). There is no setting to turn pprof off separately.
- **Why it matters.** CPU-profile requests are an easy way to load the engine. Heap and goroutine dumps can leak internal details.
- **Fix.** Add a warning on both pages. Recommend a firewall rule or a reverse proxy that exposes only `/metrics`.

#### DR-10 — Log datasources: no authentication for Kubernetes-audit, no default timeouts (Medium, missing)

- **Kubernetes-audit.** The [datasource page](https://docs.crowdsec.net/docs/log_processor/data_sources/kubernetes_audit/) lists only `listen_addr`, `listen_port`, `webhook_path` and `max_body_size`. The code has no authentication or TLS option either ([config.go L20–24](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/acquisition/modules/kubernetesaudit/config.go#L20-L24)). The page never warns that anyone who can reach the webhook can inject audit events. That is SR-1.3, and it is the entry point for our **Log-Forging Outsider**.
- **No default timeouts.** Neither HTTP server sets a read timeout by default:
  - the HTTP datasource sets one only if `timeout` is configured ([run.go L219–221](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/acquisition/modules/http/run.go#L219-L221)).
  - Kubernetes-audit never sets one ([config.go L108–112](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/acquisition/modules/kubernetesaudit/config.go#L108-L112)).
  - The [HTTP datasource page](https://docs.crowdsec.net/docs/log_processor/data_sources/http) calls `timeout` *"Optional"* and gives no default and no recommendation.
- **Fix.** Warn that the Kubernetes-audit webhook must be network-restricted. Recommend a `timeout` value, and note that `basic_auth` and header authentication send their secrets in cleartext unless `tls` is also set.

#### DR-11 — Docker (Medium, unsafe advice / missing)

- **Good on the docs site.** The [Docker page](https://docs.crowdsec.net/u/getting_started/installation/docker) publishes LAPI as `127.0.0.1:8080` ([L41](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/getting_started/installation/docker.mdx#L41)).
- **Not so in the README it links to.** For the full variable list, the docs send readers to the image README, whose run examples use `-p 8080:8080 -p 6060:6060` ([README L167](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/build/docker/README.md#L167), [L198](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/build/docker/README.md#L198)). That publishes LAPI **and** the pprof/metrics port on every host interface. Inside the container, the image binds both to `0.0.0.0` ([config.yaml L36, L51](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/build/docker/config.yaml#L36-L52)).
- **Runs as root.** The image has no `USER` directive, so it runs as root ([Dockerfile](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/build/docker/Dockerfile)). No page mentions this or how to reduce privileges.
- **Docker secrets tip only partly works.** The tip *"Use a `.env` file or Docker secrets"* ([L130](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/getting_started/installation/docker.mdx#L130)) applies only to bouncer keys, and only under Swarm (`/run/secrets/bouncer_key_*`, [docker_start.sh L506–508](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/build/docker/docker_start.sh#L506-L508)). `AGENT_PASSWORD` has no secrets or file-based variant.
- **Broken link.** The README's link to the image configuration points to a path that doesn't exist (`master/docker/config.yaml`).
- **Fix.** Bind the README examples to `127.0.0.1`. Say which secrets are actually supported. Document the root user.

#### DR-12 — Kubernetes / Helm (Medium, unsafe advice / wrong)

- **All private ranges allowed.** The [install page](https://docs.crowdsec.net/u/getting_started/installation/kubernetes)'s auto-registration example allows `192.168.0.0/16`, `10.0.0.0/8` and `172.16.0.0/12` ([L79–83](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/getting_started/installation/kubernetes.mdx#L79-L83)). That is every private address, and it contradicts the multi-server guide's *"restrict as much as possible the allowed IPs"*.
- **The Secrets example doesn't work** ([L196–222](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/getting_started/installation/kubernetes.mdx#L196-L222)):
  - Each variable sets both `valueFrom` and `value`, which Kubernetes rejects.
  - The Secret is created with key `BOUNCER_KEY_ingress` but read as `BOUNCER_KEY_traefik`.

  A reader who hits these errors is likely to fall back to plaintext keys in `values.yaml`.
- **TLS never mentioned.** The install page never mentions the Helm chart's `tls.enabled`, which defaults to `false` ([values reference L214](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/configuration/values_parameters.md#L214)).
- **Database TLS left out.** The PostgreSQL example has no `sslmode`. The reference suggests only `require` or `disable`, and neither verifies the server's identity; `verify-full` would ([L220](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/configuration/crowdsec_configuration.md#L220)).
- **Copy-paste errors in the values reference.**
  - `tls.appsec.tlsClientAuth` is described as *"for the agent when connecting to LAPI"*.
  - `tls.caBundle` shows a default of `true` ([L215, L229](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/versioned_docs/version-v1.8/configuration/values_parameters.md#L215-L229)).

### D. Installation, supply chain and data sharing

#### DR-13 — APT pinning raises the third-party repository above every package (Medium, unsafe advice)

- **What the docs say.** For Ubuntu Pro/ESM users, the [Linux page](https://docs.crowdsec.net/u/getting_started/installation/linux) says to create a pin with `Package: *` and `Pin-Priority: 1001` for the packagecloud repository ([L178–180](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/getting_started/installation/linux.mdx#L178-L180)).
- **Why it matters.**
  - `Package: *` applies the pin to every package, not just CrowdSec. Anything that repository ever publishes would outrank Ubuntu's own security updates.
  - A priority above 1000 also allows downgrades.
- **Fix.** Scope the pin to `Package: crowdsec*`, and use a priority just high enough to beat ESM without allowing downgrades.

#### DR-14 — The Splunk plugin never verifies TLS (Medium, missing)

- **What the code does.** The plugin hard-codes `InsecureSkipVerify: true` ([main.go L115–117](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/notification-splunk/main.go#L115-L117)).
- **What the docs say.** The [Splunk plugin page](https://docs.crowdsec.net/docs/local_api/notification_plugins/splunk) shows an `https://` URL and a HEC token, and says nothing about certificate verification.
- **Why it matters.** Anyone who can intercept traffic to Splunk can read or change alerts and capture the token.
- **Contrast.** The HTTP plugin does this correctly: it exposes `skip_tls_verification`, which defaults to `false` ([notification-http main.go L83](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/cmd/notification-http/main.go#L83)).
- **Fix.** Document the behavior now, and report it so the plugin gets an option.

#### DR-15 — No page says what is shared with CrowdSec by default (Medium, missing)

- **What the code does.** Alerts from custom and tainted (locally modified) scenarios are shared by default ([console.go L70–73](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/pkg/csconfig/console.go#L70-L73)).
- **What the docs say.** None of the `share_*` keys in `console.yaml` appear anywhere in the documentation:
  - The [`cscli console enable`](https://docs.crowdsec.net/docs/cscli/cscli_console_enable/) page gives a single example and no list of options.
  - The [Console enrollment page](https://docs.crowdsec.net/u/getting_started/post_installation/console/) sends readers to the [alert context guide](https://docs.crowdsec.net/u/user_guides/alert_context). That guide encourages enabling `context`, and its own example forwards `target_fqdn` hostnames, with no note that this data leaves the enterprise.
- **Fix.** Add one table listing each sharing option, its default, and exactly what it sends.

#### DR-16 — Install verification and stale requirements (Low, unsafe advice / wrong)

- **Linux.**
  - The headline method is `curl -s https://install.crowdsec.net | sudo sh` ([L23](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/getting_started/installation/linux.mdx#L23)). The GPG-verified manual method is hidden in a collapsed section.
  - The page publishes no key fingerprint to check the downloaded key against.
  - The legacy instructions for apt < 1.1 put the key in `/etc/apt/trusted.gpg.d/`, where it is trusted for every repository ([L69](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/getting_started/installation/linux.mdx#L69)). Those releases are long end-of-life, so the section can go.
- **Windows.**
  - The [Windows page](https://docs.crowdsec.net/u/getting_started/installation/windows) tells users to install the **.NET 6** runtime for the firewall bouncer ([L35](https://github.com/crowdsecurity/crowdsec-docs/blob/bad5aa9/crowdsec-docs/unversioned/getting_started/installation/windows.mdx#L35)). [.NET 6 reached end of support on 12 November 2024](https://devblogs.microsoft.com/dotnet/dotnet-6-end-of-support/), and the bouncer's current source targets .NET 10 ([csproj L5](https://github.com/crowdsecurity/cs-windows-firewall-bouncer/blob/36d3065/cs-windows-firewall-bouncer/cs-windows-firewall-bouncer.csproj#L5)).
  - The page gives no way to verify the MSI.

#### DR-17 — Security policy (Low, missing)

- [`SECURITY.md`](https://github.com/crowdsecurity/crowdsec/blob/v1.8.1/SECURITY.md) gives a reporting address but no supported-versions table and no response timeline. It links the team's GPG key through an unreleased `/docs/next/` page.
- The documentation site has no page listing the 2026 security advisories or the versions that fixed them, so an administrator can't easily tell whether their release is affected.

#### DR-18 — No hardening guide, and released pages link to unreleased docs (Low, missing)

- **No hardening guide.** We found no hardening guide or production security checklist. The pages mentioning "harden" are about WAF rule coverage, not deployment. The settings in DR-1 to DR-12 are spread across more than a dozen pages, and none of the install guides links them together.
- **Links to unreleased docs.** 165 links from the released and unversioned pages point to `/docs/next/`, the unreleased documentation. They include the links from the multi-server and LAPI-management guides to the TLS pages. A v1.8 reader can end up following instructions for a newer release.

---

### What the documentation does well

- The multi-server guide warns that *"a log processor can push arbitrary alerts to LAPI (and hence can easily lock you out)"* and makes `token` and `allowed_ranges` mandatory.
- The Docker page binds LAPI to `127.0.0.1` in its own examples.
- The NGINX page is open about the HTTP/2 body limitation and tells readers how to close it (`APPSEC_DROP_UNREADABLE_BODY`).
- The AppSec challenge protocol page has a real "Security notes" section about spoofed client-IP headers.
- The email and HTTP notification plugins default to TLS with verification, and the email page warns against port 25.
- The network management page gives a clear inventory of ports and outbound connections, which firewall rules can be built from.
- The manual repository setup uses modern `signed-by` keyrings and `repo_gpgcheck=1`.

### Summary of observations

**The documentation is accurate about features and weak on defaults and failure modes.** Almost every control our misuse case analysis relies on is documented somewhere. The problems cluster in three places:

1. **TLS guidance is unsafe or wrong** (DR-1, DR-2, DR-3, DR-5). The documentation tells readers TLS is optional on a LAN, that self-signed certificates require turning verification off, and that revocation fails where it doesn't, while missing where it does. For an enterprise multi-server deployment, this is the most important gap: it directly enables our Network-Positioned Interceptor and Bouncer-Key Thief.
2. **Fail-open behavior is undocumented** (DR-3, DR-4, DR-6, DR-9). OCSP failures, omitted `trusted_proxies`, AppSec errors and 401s all fail open, and none of them is described as such. This extends the conclusion of our alignment assessment: the controls exist, but their defaults and failure paths favor availability over security, and the documentation doesn't warn the reader.
3. **Documentation and code have drifted apart** (DR-3, DR-5, DR-7, DR-12, DR-16). In five findings the page states something the code does not do. The versioned docs make this worse: a fix has to be copied into every supported version, and the pages still link readers to unreleased docs.

A single **"Securing a production deployment"** page, linked from every install guide, would fix most of the Medium and Low findings. It would cover:

- TLS with `ca_cert_path`.
- `trusted_proxies`.
- per-bouncer keys and file permissions.
- the pprof and metrics port.
- the fail-closed AppSec settings.
- the data-sharing defaults.

The High findings still need their own pages corrected.

### Contributing back

The documentation lives in [`crowdsecurity/crowdsec-docs`](https://github.com/crowdsecurity/crowdsec-docs). Its [contribution guide](https://docs.crowdsec.net/docs/contributing/contributing_doc) accepts pull requests, including small edits through GitHub's web editor. Each pull request gets a preview build. The guide asks that versioned changes be made **across the relevant versions**, so a fix to a `/docs/` page has to go into both `docs/` (next) and `versioned_docs/version-v1.8/`. `/u/` pages live once, under `unversioned/`. The Helm values reference is generated from the chart, so DR-12's description errors have to be fixed in [`crowdsecurity/helm-charts`](https://github.com/crowdsecurity/helm-charts), not in the docs repository.

We plan to contribute in three tracks:

| Track | Findings | How |
|---|---|---|
| **1. Documentation-only pull requests** (safe to make public) | DR-5 (`SSL_VERIFY` and timeout defaults), DR-12 (invalid Secrets example), DR-13 (APT pin scope), DR-8 (token generation command, file permissions), DR-1 (remove the "not necessary on a LAN" sentence), DR-2 (replace the skip-verify advice with `ca_cert_path`), DR-16 (.NET version) | Pull requests to `crowdsec-docs`, after checking the issue tracker for duplicates |
| **2. Issues first** | DR-3 (rewrite revocation text), DR-6 (full list of failure-action cases), DR-7 (`trusted_ips` scope), DR-15 (sharing-defaults table), DR-18 (hardening page) | Open an issue to confirm intended behavior with the maintainers, then submit the pull request |
| **3. Private disclosure first** | DR-2 (skip-verify reaching CAPI), DR-3 (OCSP fail-open and misleading log), DR-4 (`trusted_proxies` default), DR-6 (possible oversized-body bypass), DR-14 (Splunk TLS) | Email `security@crowdsec.net` as `SECURITY.md` asks, and publish documentation changes only after the maintainers respond |

### Limitations

- We reviewed documentation source and code; we didn't test a running deployment. The findings that depend on runtime behavior come from reading the code and should be confirmed by testing: DR-2 (CAPI scope), DR-3 (OCSP), DR-4, DR-6 (oversized bodies) and DR-9.
- We reviewed the v1.8 documentation and v1.8.1 code. Every versioned page we cite is identical in the unreleased `docs/` tree, so none of these findings has been fixed there yet. Later engine releases may still change the code-side behavior.
- We haven't yet searched the issue trackers for existing reports of these findings.

# Canadian regulatory alignment — engineering traceability

**Snapshot date:** 2026-08-31

This document maps selected Eternal Thread controls to selected provisions of proposed
Canadian federal legislation. It is an engineering traceability note only.

This is not legal advice, a legal opinion, certification, attestation, or a claim that
Eternal Thread—or any deployment of it—complies with, is regulated by, or falls outside
any particular law. Applicability depends on facts such as who operates a deployment,
whether it is publicly accessible, what data it processes, and how it is used.

## Legislative status at this snapshot

- **Bill C-34 (45-1), Safe Social Media Act:** introduced and read a first time on
  2026-06-10; LEGISinfo lists it at second reading in the House of Commons.
- **Bill C-36 (45-1), Protecting Privacy and Consumer Data Act:** introduced and read
  a first time on 2026-06-15; LEGISinfo lists it at second reading in the House of
  Commons.

Because both are bills, their text, numbering, regulations, scope, or legal effect may
change. Re-check the official Parliament of Canada sources before each release.

Official sources:

- C-34 LEGISinfo: https://www.parl.ca/legisinfo/en/bill/45-1/c-34
- C-34 first-reading text: https://www.parl.ca/DocumentViewer/en/45-1/bill/C-34/first-reading
- C-36 LEGISinfo: https://www.parl.ca/legisinfo/en/bill/45-1/c-36
- C-36 first-reading text: https://www.parl.ca/DocumentViewer/en/45-1/bill/C-36/first-reading

## Bill C-34 — selected chatbot-safety concepts

The first-reading text defines a chatbot service using characteristics that include
Internet communication and public accessibility in Canada. Eternal Thread's default
local-first desktop configuration should therefore not be casually described as a
regulated chatbot service or as exempt from regulation; a hosted/public deployment can
materially change the analysis.

| Proposed concept | Eternal Thread control | Test/evidence | Status / residual gap |
| --- | --- | --- | --- |
| Measures addressing harmful chatbot behaviour, including deceptive professional impersonation and manipulative emotional attachment (ss. 53–54) | System instruction rejects friend/therapist substitution, dependency, secrecy and isolation; model output receives a relationship-manipulation check | `app/agent.py`, `app/safety.py`, `tests/test_privacy_and_safety.py` | **Partial engineering alignment.** Rule-based screening is narrow; requires model/language-specific evaluation and cannot establish statutory compliance. |
| Crisis-intervention measures (ss. 51–52) | Clear crisis patterns receive a bounded response directing Canadian users to 9-8-8/9-1-1 where appropriate | `app/safety.py`, `tests/test_privacy_and_safety.py` | **Partial engineering alignment.** Not a substitute for validated crisis policy, regionalization, accessibility testing, service-availability review, or trained human escalation. |
| User tools/processes to flag harmful chatbot content (s. 56) | GUI includes “Report unsafe response”; event is content-free and local | `app/gui.py`, local safety-event record | **Prototype only.** No operator case-management workflow, statutory notice process, service-level metrics, or regulator interface. |
| Resource person for a regulated chatbot service (s. 57) | None asserted | `SECURITY.md` covers vulnerability reporting only, not user digital-safety complaints | **Not implemented as a statutory function.** A regulated deployment would need a deployment-specific human complaints/resource-person process if required. |
| Digital safety plan for a regulated chatbot service (s. 58) | `DIGITAL_SAFETY_PLAN.md` documents current controls and residual risk | `DIGITAL_SAFETY_PLAN.md` | **Engineering baseline only.** It does not contain all information, measurements, reporting periods, or submission processes contemplated for a statutory plan. |

## Bill C-36 — selected privacy/data-governance concepts

| Proposed concept | Eternal Thread control | Test/evidence | Status / residual gap |
| --- | --- | --- | --- |
| Consent before collection/use/disclosure and valid consent (ss. 15–16) | Separate consent purposes for local storage, conversation indexing, knowledge indexing, web research, and non-local backend use | `app/privacy.py`, `app/main.py`, `app/gui.py`, `tests/test_privacy_and_safety.py` | **Engineering alignment.** A production notice would still need deployment-specific purpose, provider, sensitivity, and consequence disclosures. |
| Withdrawal of consent (s. 17) | Consent can be revoked from CLI/state; optional processing checks current consent before use | `ConsentStore.revoke()`, `ConsentStore.require()` | **Engineering alignment.** Withdrawal consequences and downstream third-party deletion depend on the actual deployment/provider. |
| Retention/disposal (ss. 52–54) | Configurable retention; session deletion; deletion of derived conversation RAG chunks; full local-data deletion/export commands | `app/privacy.py`, `app/main.py` | **Engineering alignment.** Appropriate retention periods and legal exceptions must be determined per deployment. |
| Security safeguards (s. 56) | Local-first storage, web SSRF mitigations, bounded requests, audit minimization, untrusted-context framing | `SECURITY.md`, `app/security.py`, `app/web.py`, tests | **Partial engineering alignment.** No claim of enterprise security accreditation; endpoint, OS, encryption, identity, monitoring, and hosted-network controls remain deployment responsibilities. |
| Transfers outside Canada (s. 57 in first-reading text) | Remote backends require explicit enablement/consent; local endpoints remain the default | `app/privacy.py`, `app/agent.py`, `config.py` | **Risk-reduction architecture, not compliance.** A real cross-border transfer may require assessments and safeguards external to this codebase. |
| Openness/transparency (s. 62) | `PRIVACY.md`, configurable retention, local data location/choices, export/delete commands | `PRIVACY.md`, GUI/CLI privacy views | **Prototype transparency.** An operator-facing privacy notice and complaint process must reflect the actual deployment and applicable law. |

## Release discipline

For every public release:

1. Re-check the official legislative status and text.
2. Update this snapshot if a bill advances, is amended, receives Royal Assent, is
   replaced, or relevant regulations/guidance are published.
3. Keep implementation status separate from legal conclusions.
4. Preserve test references for each claimed control.
5. Record residual gaps instead of describing partial controls as complete compliance.

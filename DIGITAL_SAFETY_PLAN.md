# Digital safety plan — implementation baseline

This plan records the project’s software-level controls for a local-first research
assistant. It is not a representation that the project is a regulated service, a legal
compliance document, or a substitute for a deployment-specific risk assessment. See
[REGULATORY_ALIGNMENT.md](REGULATORY_ALIGNMENT.md) for engineering traceability to
selected proposed Canadian requirements.

## Current controls

- Default safety screening for clear crisis signals, actionable interpersonal-violence
  requests, and child sexual-harm creation/acquisition/distribution requests.
- Safety-text normalization collapses superficial whitespace/Unicode formatting
  variations before deterministic matching.
- A safe crisis response that directs a Canadian user to 9-8-8 or 9-1-1 when there
  is immediate danger; no conversation content is automatically reported externally.
- Post-generation checks for explicit relationship-manipulation language and false
  claims of licensed professional authority.
- A local, content-free safety-event record and a GUI action to report unsafe output.
- Web-request SSRF protections, tool-call limits, and framing of retrieved material
  as untrusted data.
- Human review remains required before publishing an evidence assessment.

## Residual risk and release gate

Rule-based screening is incomplete and is not a semantic safety classifier. The
repository includes mild synthetic regression fixtures with opaque case IDs so routine
QA can exercise crisis, harmful-instruction, manipulation, authority, privacy, and
false-positive boundaries without repeatedly surfacing graphic scenarios. Before public
or youth-facing deployment, independently test the selected models and every supported
language against harmful content, crisis, manipulation, prompt-injection, privacy,
accessibility, and false-positive scenarios. Publish the model/version coverage, failure
criteria, response process, and corrective actions for each release.

Do not configure the assistant to simulate friendship, intimacy, therapeutic care,
or exclusivity. Do not make safety-event logs a covert user-monitoring channel.

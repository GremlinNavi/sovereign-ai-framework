# Portable host architecture

Eternal Thread is designed so that the AI workflow is not permanently coupled to a
single model, inference runtime, operating system, hardware vendor, or software
forge. SteamOS, Proton, and the wider Linux handheld ecosystem are useful reference
platforms for this design philosophy, but they are not project dependencies and are
not redistributed by this repository.

## Why SteamOS is relevant

SteamOS demonstrates that a Linux-based consumer system can combine an open-source
operating-system foundation with centrally managed updates, portable hardware,
standard USB-C expansion, and access to a large commercial software ecosystem.
For Eternal Thread, the significance is architectural rather than product-specific:
a local-first AI framework can run on ordinary consumer hardware while remaining
separable from the hardware vendor's cloud services.

A Steam Deck-class host can operate in more than one role:

```text
undocked
  handheld computer
      -> SteamOS/Linux
      -> project-specific Python .venv
      -> Eternal Thread
      -> configured local inference backend

Docked
  the same host
      -> continuous USB-C power
      -> Ethernet
      -> external storage
      -> display and input devices
      -> optional trusted local inference nodes
```

Docking therefore changes the physical topology without requiring the research
workflow, local records, or configuration model to change identity.

## Proton as a maintained compatibility substrate

Proton is relevant beyond games because it is a versioned, continuously maintained
Windows-on-Linux compatibility layer distributed through Steam. Steam also distributes
non-game software, so Proton can increase the practical software surface available to
a Linux-based portable workstation without requiring the native AI framework itself
to become Windows-dependent.

Eternal Thread should remain native to Linux where practical. Proton is best treated
as an optional compatibility branch for Windows-only applications or utilities:

```text
SteamOS/Linux
  |-- native Linux applications
  |-- Eternal Thread
  |     -> Python .venv
  |     -> configured AI backend
  |
  `-- Proton
        -> selected Windows-only software
```

The important design principle is loose coupling. A Proton update, application
update, model update, backend update, or Eternal Thread update should not inherently
require rebuilding every other layer.

## Steam's software database and update network

Steam provides more than executable delivery. Its application identities, update
channels, compatibility information, and Proton versioning create a large-scale
software-maintenance network. A portable Linux host can therefore inherit ongoing
compatibility improvements that are economically sustained by a much larger software
and gaming ecosystem.

This is useful as a systems-design precedent: Eternal Thread does not need to own the
compatibility problem for every program that may be useful beside it. Existing
software ecosystems can remain independent components around the framework.

## Forks, mirrors, and sovereign computing

SteamOS-related source packages, community derivatives, mirrors, and SteamOS-like
projects hosted on Git forges such as GitHub and GitLab demonstrate another important
principle: an open computing architecture can be studied, reproduced, modified, and
adapted without requiring every downstream user to accept one immutable vendor image.

For sovereign or public-interest computing, the significant property is not that a
particular SteamOS fork should be adopted. The useful property is that open components
and build knowledge can be recomposed under different hardware, security, update, and
deployment policies.

A general pattern is:

```text
upstream open components
        -> version-controlled source
        -> downstream fork or configuration
        -> local security and deployment policy
        -> reproducible build/test process
        -> deployable host environment
        -> improvements can flow upstream again
```

Git also provides historical resilience. Known-good revisions can be retained,
regressions compared, security fixes backported, and repositories mirrored across
multiple forges or stored offline. This complements Eternal Thread's own goal of
remaining reproducible and difficult to bind permanently to one vendor or service.

## Relevance to Canadian open computing

This project is Canadian-developed, but technological sovereignty does not require
reimplementing every lower layer domestically. A more practical model is to combine
well-governed open technologies with Canadian-controlled configuration, data,
security policy, deployment, and maintenance.

SteamOS-like systems are therefore useful as reference architectures for questions
such as:

- Can a consumer-facing Linux system remain usable while its underlying components
  stay replaceable?
- Can application compatibility be separated from the host operating system?
- Can update infrastructure coexist with local control?
- Can an organization retain known-good builds and configuration state?
- Can a portable host continue useful local computation when cloud services are
  unavailable or deliberately excluded?

Eternal Thread explores the same principle one layer higher: the AI workflow should
remain useful when models, runtimes, hosts, or distribution services change.

## Configuration-driven host profiles

A future research direction is to apply the project's current configuration-first
approach to host environments. A PowerShell or other orchestration layer could read a
declarative profile and generate Linux-native configuration for a reproducible host
image or deployment.

For example, a profile might describe:

```text
network
  local-only inference: required
  public web research: disabled

services
  ssh: disabled
  unnecessary daemons: disabled

storage
  encrypted user data: required
  external model storage: allowed

software
  Eternal Thread: native Linux
  Python environment: recreated from lock files
  Windows compatibility: optional Proton channel
```

The orchestration layer should delegate privileged operating-system construction to
Linux-native image, package, service, firewall, and signing tools rather than attempt
to replace them.

## Virtual-environment boundary

A Python virtual environment is part of Eternal Thread's execution contract. Create
and activate a fresh project-specific `.venv` on each host before installing the
reviewed dependency set and running the application. Do not copy a `.venv` between
machines as the portable artifact.

The portable artifact is the reproducible recipe:

```text
source
+ dependency lock files
+ configuration
+ release metadata
+ optional model/data manifests
= environment that can be reconstructed on a compatible host
```

A `.venv` provides Python dependency isolation and reproducibility. It is not a
security sandbox. Filesystem, process, device, and network isolation remain the
responsibility of the host operating system and deployment policy.

## Portable-copy model

For removable media or a docked portable workstation, prefer storing the framework,
lock files, release metadata, model manifests or permitted model files, and optional
user-controlled knowledge separately from the generated Python environment.

This supports a resilient workflow:

```text
public Git repository / mirrored forge / release archive
                    |
                    v
             portable source copy
                    |
                    v
           recreate local .venv
                    |
                    v
       validate configured backend/model
                    |
                    v
              run regression tests
                    |
                    v
             operate locally
```

The goal is deployment portability rather than dependence on any particular Steam
product. Steam Deck and SteamOS are valuable test platforms because they combine
portable x86 hardware, Linux, standardized expansion, managed software distribution,
and a mature compatibility ecosystem in one consumer device.

## Project boundary

Eternal Thread is not affiliated with, endorsed by, or a product of Valve. Steam,
SteamOS, Steam Deck, and Proton remain subject to their respective licenses, terms,
and trademarks. Any future derivative operating-system work must verify the
redistribution rights and provenance of every included component. When a Valve-specific
component is unnecessary, prefer open, cleanly licensed, replaceable interfaces and
host-independent configuration.

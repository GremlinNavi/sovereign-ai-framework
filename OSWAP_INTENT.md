# OSWAP Intent: Resilient, Survivor-Controlled Information Infrastructure

SPDX-License-Identifier: Apache-2.0

This document records the design intent behind the OSWAP Standard. It is explanatory rather than a substitute for the normative requirements in `OSWAP_STANDARD.md`.

## Why this exists

OSWAP is designed around a simple observation: real-world information can be lost or suppressed before any institution has an opportunity to evaluate it.

Repository loss, account takeover, device destruction, platform removal, coercive deletion, institutional capture, and ordinary hardware failure can all erase records. A preservation system therefore has value even when no lawsuit, police report, journalistic publication, or other formal process occurs.

OSWAP treats preservation as a user-controlled capability.

## Information should survive coercion

For sensitive records, the primary question is not only:

> How can this later be proved to an authority?

It is also:

> How can the person prevent what happened from becoming erasable?

Accordingly, OSWAP preservation is intended to support:

- personal incident records;
- domestic-violence and coercive-control documentation;
- whistleblower source preservation;
- human-rights documentation;
- community and minority-history archiving;
- ordinary private records that a user cannot safely afford to lose.

No category above authorizes access to somebody else's systems. OSWAP only handles material the user is entitled to possess and preserve.

## Preservation is not publication

Public open-source knowledge and sensitive personal evidence have different threat models.

OSWAP therefore follows an asymmetric principle:

```text
public knowledge -> replicate openly when appropriate
private identity/evidence -> minimize exposure and replicate protected ciphertext
```

A sensitive preservation package should remain under the user's control until that user deliberately chooses disclosure.

## Safety model

OSWAP assumes that a device may be observable.

It does not promise stealth against spyware or privileged monitoring. If a device may be compromised, the safer action is to stop and move to a trusted device.

The software should minimize unnecessary traces, but it must not weaken operating-system security controls or use malware-like evasion techniques.

## Human-facing design

Safety-sensitive OSWAP workflows are intentionally prompt-driven in PowerShell-compatible terminals.

The goal is to keep dangerous or sensitive values out of command-line history and process arguments while presenting each side effect in plain language.

A user should be able to understand:

- what will be copied;
- what will be hashed;
- what will be encrypted;
- what will be committed;
- where ciphertext may be pushed;
- what remains local;
- what cancellation will leave behind.

## Distributed custody

OSWAP's `twin` model treats repository hosts as participating custodians rather than as the ontology of the project.

A project or archive should be capable of existing across independent infrastructure. Fractional twin factors provide a compact way to express replication intensity while preserving whole-copy semantics.

For example:

```text
oswap push twin=(4+3)/2
```

means a replication factor of `3.5`: three whole destination copies are guaranteed and a fourth is selected with 50% probability.

## Autonomy

Coercive control is fundamentally a problem of concentrated control. OSWAP should not answer that problem by transferring control to a developer, platform, maintainer, police service, or other authority.

The user retains the decision to preserve, replicate, decrypt, disclose, delete local material, or seek outside assistance.

## Engineering discipline

This intent should be implemented through:

- restricted parsing rather than arbitrary evaluation;
- SHA-256 integrity manifests;
- encryption before remote replication of sensitive material;
- generic external package identifiers;
- explicit confirmation before remote writes;
- independent destination support;
- auditability and open licensing;
- tests that fail closed when safety invariants are violated.

OSWAP-authored code and documentation implementing this intent are licensed under Apache-2.0 when included in an OSWAP repository carrying that license.

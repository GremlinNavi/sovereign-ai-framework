# OSWAPSACW ChatGPT Plugin — Testing and Semantic Contract

Date: 2026-09-02
Status: Experimental open-source specification and conformance documentation

## Purpose

This document defines testable behavior for the OSWAP Standard for Auditable Code Workflows (OSWAPSACW) ChatGPT Plugin prototype.

The Plugin treats OSWAP commands as auditable declarations of intent. Parsing, authorization, execution, and verification are separate phases.

## Core semantic separation

`twin` and `joker` are independent control dimensions:

```text
twin = cardinality
       how many independently selected copies, sources, endpoints, or authorities participate?

joker = policy
        how should eligible copies, sources, endpoints, or authorities be selected or used?
```

The implementation MUST NOT reinterpret `joker` as a synonym for `twin`, or infer arbitrary shell execution from either expression.

Canonical transfer examples:

```text
oswap upload twin=3
oswap download twin=(9/3)
```

## Multiplicity and publisher authorization

OSWAP permits multiple independently authorized publishing principals, services, repositories, or automation agents to coexist under one project namespace.

A publisher principal is an authorization subject, not a claim about a person's psychological, social, legal, or singular identity. Implementations MUST NOT require a one-human-to-one-principal mapping.

Credential state is evaluated independently from the principal or project namespace. A compromised signing credential can therefore be revoked and replaced without erasing historical attribution or requiring the project to redefine a person.

## Consent and execution tests

The bundled PowerShell conformance test MUST verify:

- canonical `twin` upload and download parsing;
- restricted arithmetic grammar with no `Invoke-Expression` or arbitrary shell evaluation;
- `upload` classification as `remote_write`;
- `download` classification as `local_write`;
- fail-closed behavior for denied or missing authorization;
- explicit separation of `twin` cardinality from `joker` policy;
- plugin manifest, connected-app, MCP, consent-schema, and audit-schema integrity.

## Expected security behavior

A successful parse is not authorization. Authorization is not proof of execution. Execution is not proof of success. Verification is recorded separately.

Remote publication MUST remain subject to the provider's actual permissions in addition to OSWAPSACW's consent gate.

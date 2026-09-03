# Engineering overview

This document gives reviewers a compact technical map of the Sovereign AI Demonstrator and its OSWAP integration.

## What the implementation demonstrates

- Backend abstraction for local chat and embedding runtimes.
- Hybrid local retrieval using conversation, knowledge, and fetched public-web content.
- Explicit capability checks before tool-calling or structured-output workflows run.
- URL validation, redirect revalidation, bounded downloads, and untrusted-context framing.
- Granular consent, local audit records, export/delete controls, and human-review gates.
- Restricted OSWAP arithmetic parsing without arbitrary PowerShell evaluation.
- Preview-first repository publication with explicit authorization before remote writes.

## Engineering approach

The project separates declarative intent, validation, planning, consequential execution, and verification. Safety-sensitive operations fail closed rather than silently weakening policy. Provider-specific AI and repository services are treated as replaceable adapters rather than project identity.

## Validation evidence

The repository includes pytest regression tests, PowerShell syntax tests, locked dependency sets, GitHub Actions CI across Windows/Linux and Python 3.10/3.12, release checks, and security/contribution policies. A GitLab Python CI definition is also maintained; runner validation remains a release gate.

## Current limitations

This is a release-candidate reference implementation, not a production service. Wider backend certification, cross-forge CI parity, signed/SBOM-backed releases, operational OSWAP endpoints, and broader independent security review remain future work.

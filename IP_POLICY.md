# Intellectual property and release policy

This policy documents the project’s intended release practice. It is not legal
advice, a patent filing, a trademark registration, or a substitute for a written
employment, contractor, or contributor agreement.

## Scope and ownership

Original project material is identified by the copyright and attribution notices in
this repository. Apache-2.0 is an outbound public licence: it grants defined rights
to recipients but does not itself transfer copyright ownership from a contributor to
the project maintainer. Contributors retain ownership of their original work unless
a separate written agreement says otherwise.

Every contributor must comply with [DCO.md](DCO.md). Maintainers must keep executed
employment, contractor, assignment, or contributor agreements outside the public
repository where they are needed to establish a chain of title.

## Public and private boundaries

Do not commit or publish:

- API keys, credentials, certificates, tokens, or production configuration;
- personal data, private conversations, audit records, customer data, or private
  research material;
- third-party material without a documented right to use and redistribute it; or
- an invention’s enabling technical detail if patent protection is still being
  considered.

A deleted public Git commit may persist in clones, forks, caches, and release
archives. Revoke exposed credentials immediately; do not treat history rewriting as
a complete remedy.

## Releases

Each public release must retain the Apache-2.0 `LICENSE`, project `NOTICE`, source
copyright/SPDX identifiers, `THIRD_PARTY_NOTICES.md`, `SBOM.cdx.json`, and a
published SHA-256 checksum for every release asset. Regenerate the third-party
notices and SBOM from a clean, reviewed version-pinned build environment before publishing.

## Patent and trademark decisions

Patent candidates and brand-clearance decisions must be made before a public
release. No project file represents that a CIPO patent or trademark application has
been made, or that any mark is registered. Use `®` only after registration;
`™` may be used only as an unregistered brand claim after the owner has approved the
claim.

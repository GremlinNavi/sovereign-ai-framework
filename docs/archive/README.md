# Public archive records

This directory records release and retained-source evidence that can safely be made
public. It is an index to immutable host references and checksums, not a store for
personal project data or private archives.

## Privacy boundary

Archive records must never include conversation histories, audit or safety logs,
knowledge indexes or files, training/review data, local configuration, credentials,
private keys, certificates, user exports, or machine-specific build environments.
Release ZIPs and executable assets belong in the corresponding host release, with a
SHA-256 manifest; they are not committed to the source tree.

## Record requirements

For each hosted release, add a versioned record containing:

- the exact GitHub and GitLab tag or immutable commit references;
- source and executable asset filenames with their SHA-256 values;
- the checksum-manifest filename and hash;
- verification command, result, and date;
- SBOM and third-party-notice provenance; and
- an explicit list of withheld private-data categories.

GitHub is the canonical public source for this project. Maintainer-controlled GitLab
copies are archival mirrors whose visibility and release status may differ. The two
hosts can have different commit IDs while representing the same reviewed source tree;
that fact must be documented, not hidden by force-pushing history.

## Index

- [v0.4.0-rc3](v0.4.0-rc3.md) — source-input and pre-release import record; not yet
  a tagged hosted release or an asset manifest.

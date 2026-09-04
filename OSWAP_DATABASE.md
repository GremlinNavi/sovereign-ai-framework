# Open-Source World Access Project (OSWAP) Database

## Purpose

The Open-Source World Access Project (OSWAP) database is a planned, open, auditable software-discovery catalogue for locating open-source software across multiple forges, package registries, and distribution sources.

OSWAP is intended to preserve factual metadata and provenance while keeping ranking logic replaceable and inspectable. Popularity may be recorded, but popularity is not treated as authority or relevance by default.

## Relationship to this repository

The OSWAP AI Demonstrator and the OSWAP database are distinct components of the broader OSWAP project that may interoperate in the future.

- `knowledge/index.sqlite3` is the OSWAP AI Demonstrator's local RAG/vector index.
- The OSWAP database is a separate software-access and discovery catalogue.
- OSWAP data must not be silently merged into the runtime RAG index or treated as trusted model instructions.

## Canonical storage model

For the initial implementation:

- SQLite is the canonical local database format.
- JSONL is the portable interchange/export format.
- Source provenance is first-class metadata.
- Search/ranking is implemented above the factual data layer rather than embedded as an opaque quality score.

## Core entities

A normalized OSWAP record should distinguish software identity from repositories and distribution artifacts.

```text
Project
├── repositories
├── releases
├── artifacts
├── platforms
├── licenses
├── tags
└── provenance/source records
```

Recommended tables for an initial schema:

- `projects`
- `repositories`
- `releases`
- `artifacts`
- `platforms`
- `project_platforms`
- `licenses`
- `sources`
- `source_records`
- `tags`
- `project_tags`

## Provenance requirements

Imported metadata should retain its origin, retrieval time, upstream identifier or URL, and a content hash where practical. Conflicting upstream values should remain attributable rather than being silently overwritten.

Potential source adapters include GitHub, GitLab, Obtainium/App Finder data, package registries, independent forges, and project-maintained feeds.

## Search principles

OSWAP should support transparent, user-selectable discovery modes such as exact relevance, alphabetical order, recently updated, popularity, random discovery, and resource/platform filters.

Search results should be able to explain why a result appeared and which source supplied the relevant metadata.

## Branding

Formal name: Open-Source World Access Project

Short form: OSWAP

Database name in documentation: OSWAP Database

OSWAP is an independent open-source project name and is not affiliated with the OWASP Foundation or the Open Worldwide Application Security Project.

## Status

This document defines the planned database boundary and naming convention. It does not claim that the full OSWAP ingestion, normalization, or search stack is already implemented in the OSWAP AI Demonstrator.

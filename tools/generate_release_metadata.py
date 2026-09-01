# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

"""Generate reproducible third-party notices and a CycloneDX SBOM from lock files."""
from __future__ import annotations

import argparse
import json
import os
import re
from datetime import UTC, datetime
from importlib import metadata
from pathlib import Path


REQUIREMENT = re.compile(r"^([A-Za-z0-9_.-]+)==([^\s;]+)$")


def _locked_packages(requirements_file: Path, seen: set[Path] | None = None) -> dict[str, str]:
    seen = seen or set()
    resolved = requirements_file.resolve()
    if resolved in seen:
        return {}
    seen.add(resolved)
    packages: dict[str, str] = {}
    for raw in requirements_file.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        if line.startswith("-r "):
            packages.update(_locked_packages(requirements_file.parent / line[3:].strip(), seen))
            continue
        match = REQUIREMENT.fullmatch(line)
        if not match:
            raise ValueError(f"Unsupported requirement line in {requirements_file}: {raw}")
        packages[match.group(1).lower().replace("_", "-")] = match.group(2)
    return packages


def _license_text(distribution: metadata.Distribution) -> str:
    for file in distribution.files or []:
        normalized = str(file).replace("\\", "/")
        filename = Path(normalized).name.lower()
        if "/licenses/" in normalized.lower() or filename.startswith(("license", "copying", "notice")):
            try:
                text = distribution.locate_file(file).read_text(encoding="utf-8", errors="replace")
                return "\n".join(line.rstrip() for line in text.splitlines()).rstrip()
            except OSError:
                continue
    return "No licence text was found in this installed distribution. Consult its published package metadata."


def _declared_license(distribution: metadata.Distribution) -> str:
    return distribution.metadata.get("License-Expression") or distribution.metadata.get("License") or "See included licence text"


def _distribution(name: str, version: str) -> metadata.Distribution:
    distribution = metadata.distribution(name)
    if distribution.version != version:
        raise RuntimeError(f"{name} is {distribution.version}, but the lock file requires {version}")
    return distribution


def _timestamp(value: str | None) -> str:
    if value:
        return value
    epoch = os.environ.get("SOURCE_DATE_EPOCH")
    if epoch:
        return datetime.fromtimestamp(int(epoch), UTC).isoformat().replace("+00:00", "Z")
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")


def generate(root: Path, notices_output: Path, sbom_output: Path, timestamp: str | None) -> None:
    locks = ("requirements.lock", "requirements-test.lock", "requirements-build.lock")
    packages: dict[str, str] = {}
    for filename in locks:
        packages.update(_locked_packages(root / filename))

    distributions = [(name, version, _distribution(name, version)) for name, version in sorted(packages.items())]

    notice_lines = [
        "# Third-party notices",
        "",
        "Generated from the version-pinned Python distributions named in `requirements.lock`,",
        "`requirements-test.lock`, and `requirements-build.lock`.",
        "Regenerate this file whenever a lock file changes, using a clean reviewed",
        "environment constructed from the version-pinned lock files.",
        "",
    ]
    components = []
    for name, version, distribution in distributions:
        declared_license = _declared_license(distribution)
        notice_lines.extend([
            f"## {distribution.metadata['Name']} {version}",
            "",
            f"Declared licence: {declared_license}",
            "",
            _license_text(distribution),
            "",
        ])
        components.append({
            "type": "library",
            "name": distribution.metadata["Name"],
            "version": version,
            "purl": f"pkg:pypi/{name}@{version}",
            "licenses": [{"license": {"name": declared_license}}],
        })

    notices_output.write_text("\n".join(notice_lines), encoding="utf-8", newline="\n")
    sbom = {
        "$schema": "https://cyclonedx.org/schema/bom-1.5.schema.json",
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "serialNumber": "urn:uuid:7e40c29a-66bb-5391-bcef-e9252cda56f6",
        "version": 1,
        "metadata": {
            "timestamp": _timestamp(timestamp),
            "component": {
                "type": "application",
                "name": "eternal-thread",
                "version": "0.4.0rc4",
                "licenses": [{"license": {"id": "Apache-2.0"}}],
            },
            "tools": [{"vendor": "Eternal Thread", "name": "generate_release_metadata.py"}],
        },
        "components": components,
    }
    sbom_output.write_text(json.dumps(sbom, indent=2) + "\n", encoding="utf-8", newline="\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--notices", type=Path, default=Path("THIRD_PARTY_NOTICES.md"))
    parser.add_argument("--sbom", type=Path, default=Path("SBOM.cdx.json"))
    parser.add_argument("--timestamp", help="RFC 3339 timestamp; use a release timestamp for reproducible output")
    args = parser.parse_args()
    generate(args.root.resolve(), args.notices, args.sbom, args.timestamp)

# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

"""Generate an auditable licence-notice file for installed Python distributions."""
from __future__ import annotations

import argparse
from importlib import metadata
from pathlib import Path


def _licence_text(distribution: metadata.Distribution) -> str:
    for file in distribution.files or []:
        name = str(file).replace("\\", "/")
        if "/licenses/" in name.lower() or Path(name).name.lower().startswith(("license", "copying", "notice")):
            try:
                return distribution.locate_file(file).read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
    return "No licence text was found in the installed distribution; consult its published package metadata."


def generate(output: Path) -> None:
    lines = [
        "# Third-party notices",
        "",
        "This file is generated from the Python distributions installed for this build.",
        "It must be regenerated whenever the locked dependency set changes.",
        "",
    ]
    distributions = sorted(metadata.distributions(), key=lambda item: item.metadata["Name"].lower())
    for distribution in distributions:
        name = distribution.metadata["Name"]
        if not name:
            continue
        licence = distribution.metadata.get("License-Expression") or distribution.metadata.get("License") or "See included licence text"
        lines.extend([
            f"## {name} {distribution.version}",
            "",
            f"Declared licence: {licence}",
            "",
            _licence_text(distribution).rstrip(),
            "",
        ])
    output.write_text("\n".join(lines), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    generate(args.output)

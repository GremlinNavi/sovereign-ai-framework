"""Command-line entry point for inspecting OSWAP plans without executing them."""
from __future__ import annotations

import argparse
import json

from .planner import plan_command


def main() -> int:
    parser = argparse.ArgumentParser(description="Compile an OSWAP command into a dry-run plan")
    parser.add_argument("--command", required=True, help="OSWAP command to plan")
    parser.add_argument("--max-twins", type=int, default=100)
    args = parser.parse_args()
    plan = plan_command(args.command, max_twins=args.max_twins)
    print(json.dumps(plan.to_dict(), indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

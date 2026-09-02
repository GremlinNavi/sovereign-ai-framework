"""Compile a deliberately small OSWAP command subset into dry-run plans."""
from __future__ import annotations

import re

from .expressions import ExpressionError, evaluate_expression, require_positive_integer
from .ir import OSWAPPlan


class PlanError(ValueError):
    """Raised when a command cannot be represented by the current OSWAP planner."""


_PUSH = re.compile(r"^\s*oswap\s+push\s+twin=(?P<expression>.+?)\s*$", re.IGNORECASE)


def plan_command(command: str, *, max_twins: int = 100) -> OSWAPPlan:
    """Parse an OSWAP command and return a side-effect-free execution plan."""
    match = _PUSH.fullmatch(command)
    if not match:
        raise PlanError("Supported prototype syntax: oswap push twin=<expression>")
    expression = match.group("expression")
    try:
        value = require_positive_integer(evaluate_expression(expression), maximum=max_twins)
    except ExpressionError as exc:
        raise PlanError(str(exc)) from exc
    return OSWAPPlan(
        operation="repository.push",
        allocation_mode="twin",
        expression=expression,
        resolved_value=value,
        dry_run=True,
    )

"""Safe evaluator for the OSWAP Order-of-Operations expression subset.

OSWAP defines ``^`` as exponentiation. Expressions are parsed with Python's AST only
after normalization; names, calls, attributes, indexing, assignments and all other
syntax are rejected. This module never calls eval(), exec(), or a shell.
"""
from __future__ import annotations

import ast
from fractions import Fraction


class ExpressionError(ValueError):
    """Raised when an OSWAP arithmetic expression is invalid or unsafe."""


MAX_SOURCE_LENGTH = 256
MAX_EXPONENT = 64
MAX_RESULT_BITS = 4096


def _bounded(value: Fraction) -> Fraction:
    if value.numerator.bit_length() > MAX_RESULT_BITS or value.denominator.bit_length() > MAX_RESULT_BITS:
        raise ExpressionError("Expression result exceeds the configured numeric safety bound")
    return value


def _evaluate(node: ast.AST) -> Fraction:
    if isinstance(node, ast.Expression):
        return _evaluate(node.body)
    if isinstance(node, ast.Constant) and isinstance(node.value, int) and not isinstance(node.value, bool):
        return Fraction(node.value)
    if isinstance(node, ast.UnaryOp) and isinstance(node.op, (ast.UAdd, ast.USub)):
        value = _evaluate(node.operand)
        return value if isinstance(node.op, ast.UAdd) else -value
    if isinstance(node, ast.BinOp):
        left = _evaluate(node.left)
        right = _evaluate(node.right)
        if isinstance(node.op, ast.Add):
            return _bounded(left + right)
        if isinstance(node.op, ast.Sub):
            return _bounded(left - right)
        if isinstance(node.op, ast.Mult):
            return _bounded(left * right)
        if isinstance(node.op, ast.Div):
            if right == 0:
                raise ExpressionError("Division by zero")
            return _bounded(left / right)
        if isinstance(node.op, ast.Pow):
            if right.denominator != 1:
                raise ExpressionError("Exponent must resolve to an integer")
            exponent = right.numerator
            if exponent < 0 or exponent > MAX_EXPONENT:
                raise ExpressionError(f"Exponent must be between 0 and {MAX_EXPONENT}")
            return _bounded(left ** exponent)
    raise ExpressionError(f"Unsupported expression element: {type(node).__name__}")


def evaluate_expression(source: str) -> Fraction:
    """Evaluate one deterministic OSWAP arithmetic expression."""
    source = source.strip()
    if not source:
        raise ExpressionError("Expression is empty")
    if len(source) > MAX_SOURCE_LENGTH:
        raise ExpressionError("Expression is too long")
    if "**" in source:
        raise ExpressionError("Use '^' for exponentiation in canonical OSWAP syntax")
    normalized = source.replace("^", "**")
    try:
        tree = ast.parse(normalized, mode="eval")
    except SyntaxError as exc:
        raise ExpressionError("Invalid arithmetic syntax") from exc
    return _evaluate(tree)


def require_positive_integer(value: Fraction, *, maximum: int = 100) -> int:
    """Validate a resolved value for resource-allocation uses such as twin counts."""
    if value.denominator != 1:
        raise ExpressionError("Allocation result must be an integer")
    result = value.numerator
    if result < 1:
        raise ExpressionError("Allocation result must be positive")
    if result > maximum:
        raise ExpressionError(f"Allocation result exceeds configured maximum of {maximum}")
    return result

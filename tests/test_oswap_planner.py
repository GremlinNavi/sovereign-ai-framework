import pytest

from app.oswap.expressions import ExpressionError, evaluate_expression
from app.oswap.planner import PlanError, plan_command


def test_canonical_expression_resolves_to_fifty():
    plan = plan_command("oswap push twin=4*(15-(2^3-5))+18/3^2")
    assert plan.resolved_value == 50
    assert plan.operation == "repository.push"
    assert plan.dry_run is True


def test_valid_arithmetic_can_fail_allocation_validation():
    with pytest.raises(PlanError, match="positive"):
        plan_command("oswap push twin=4*(15-(23-5))+18/3^2")


def test_calls_are_not_executable_expression_elements():
    with pytest.raises(ExpressionError):
        evaluate_expression("__import__('os').system(1)")


def test_python_power_operator_is_not_canonical_oswap_syntax():
    with pytest.raises(ExpressionError, match="Use '\^'"):
        evaluate_expression("2**3")

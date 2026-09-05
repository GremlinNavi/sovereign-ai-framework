# OSWAP semantic execution layer

## Status

Prototype planning interface. It is intentionally side-effect free.

OSWAP means Open-Source World Access Project. The Sovereign AI Demonstrator remains a separate project and acts here as a reference client for deterministic OSWAP planning.

## Boundary

The intended boundary is:

```text
human request
    -> local or compatible LLM
    -> OSWAP command / structured request
    -> deterministic parser
    -> OSWAP intermediate representation
    -> arithmetic validation
    -> policy and consent (future)
    -> adapter execution (future)
```

The LLM interprets intent. It does not receive unrestricted shell authority from this layer.

## Current prototype

The current planner accepts one command family:

```text
oswap push twin=<expression>
```

Example:

```text
oswap push twin=4*(15-(2^3-5))+18/3^2
```

The expression resolves to 50 and the planner emits a JSON-compatible dry-run plan for `repository.push` with twin allocation 50.

The expression `4*(15-(23-5))+18/3^2` resolves to -10. Arithmetic parsing succeeds, but allocation validation rejects the result because a twin count must be a positive integer.

## Security properties

- `^` is OSWAP exponentiation.
- Python `eval()` and `exec()` are not used.
- Names, calls, attributes, indexing and assignments are rejected by the expression evaluator.
- Division is represented exactly with rational arithmetic before semantic validation.
- Exponent and result-size limits bound pathological arithmetic.
- The planner does not run Git, PowerShell commands, network requests or filesystem mutations.

## Integration direction

A future agent tool should expose planning before execution, for example `plan_oswap_command(command)`. Execution should remain a separate capability requiring explicit policy and consent checks. OSWAP IR should remain backend-independent so Git, storage, compute and simulator adapters can share the same semantic layer.

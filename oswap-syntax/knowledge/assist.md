# OSWAP local PowerShell assistance

Canonical form:

```text
oswap assist powershell <TASK>
```

The reference implementation calls a local Ollama-compatible endpoint at `http://127.0.0.1:11434/api/chat`. The model can be selected with `OSWAP_LLM_MODEL`; the lightweight fallback is `qwen3:4b`.

This command is advisory, not agentic. It sends the requested coding task to the configured local model and prints the response. It does not execute generated PowerShell, invoke tools, write files, commit changes, or publish repositories.

Human review remains the execution boundary. A future remote-provider adapter must require explicit consent and must not silently replace the local endpoint.

The model layer is intentionally replaceable so OSWAP syntax, dictionary lookup, repository verification, and human authorization do not depend on one model family or vendor.

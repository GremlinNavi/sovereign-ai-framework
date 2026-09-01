# Upstream model and runtime references

This document records human-readable canonical links for the default model families
and local inference-runtime projects relevant to Eternal Thread. It supports future
migration research if a model, model host, package, or runtime is changed or
discontinued.

These links are **references, not bundled dependencies or endorsements**. Eternal
Thread does not download, install, redistribute, or guarantee compatibility with any
listed model or runtime. Each operator must review upstream licensing, security,
hardware requirements, data handling, capabilities, and current availability before
using a replacement.

## Attribution and rights boundary

The names, source repositories, model cards, model files, trademarks, copyrights,
and licences of the projects below belong to their respective upstream rightsholders.
The linked source page or model card is authoritative for its current licence and
attribution requirements. Licence labels below are recorded as displayed by those
linked pages when this RC4 documentation was updated; they are not legal advice and
must be rechecked before a new deployment or redistribution.

Because these components are not bundled with Eternal Thread, this reference record
does not substitute for their own licence notices, and it does not add them to this
project's `THIRD_PARTY_NOTICES.md`. If a future distribution actually includes an
upstream runtime, model artifact, or code, its applicable notices and licences must
be reviewed and included at that time.

## Current default references

| Framework role | Configured default | Upstream attribution and canonical reference | Licence shown upstream at record time | Migration note |
| --- | --- | --- | --- | --- |
| Local inference runtime | Ollama | Ollama project — <https://github.com/ollama/ollama> | MIT | The project uses Ollama as a default adapter; it is not bundled with Eternal Thread. |
| Chat-model family | `qwen3:4b` | Qwen / Qwen3-4B model card — <https://huggingface.co/Qwen/Qwen3-4B> | Apache-2.0 | This is an upstream model-family reference, not a claim that every Ollama artifact with this tag has identical weights, quantization, licence, or behaviour. |
| Embedding-model family | `nomic-embed-text` | Nomic AI / nomic-embed-text-v1.5 model card — <https://huggingface.co/nomic-ai/nomic-embed-text-v1.5> | Apache-2.0 | Rebuild the local retrieval index after changing this model or any embedding backend. |

## Additional local-runtime source projects

These projects are useful starting points when researching a replacement local
runtime that can provide the capabilities required by the configured adapter. They
are not automatically supported, installed, or tested by this release.

| Project | Upstream attribution and canonical source repository | Licence shown upstream at record time | Check before using |
| --- | --- | --- | --- |
| llama.cpp | ggml-org / llama.cpp — <https://github.com/ggml-org/llama.cpp> | MIT | Endpoint compatibility, required chat/embedding capabilities, hardware support, and local security controls. |
| vLLM | vLLM Project / vLLM — <https://github.com/vllm-project/vllm> | Apache-2.0 | Endpoint compatibility, platform support, resource requirements, and the model's separate licence. |

## Migration and archival practice

If an upstream component is sunsetted, choose and configure a compatible replacement
deliberately. Run the configuration health check and the relevant test suite before
relying on it. A chat-model replacement can preserve source code and local records;
an embedding-model replacement requires a fresh index because vector representations
from different embedding models must not be mixed.

A canonical web link is useful, but it is not a permanence guarantee. For any
specific deployment or public release, also record the exact model/runtime version,
model artifact identifier or checksum where available, date retrieved, applicable
licence, and a retained archival copy of the relevant release metadata. Do not store
private access tokens, credentials, or private model files in this repository.

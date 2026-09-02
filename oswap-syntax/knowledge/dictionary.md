# OSWAP multilingual dictionary layer

Canonical form:

```text
oswap dictionary lookup lang=<BCP47> term=<TEXT>
```

The dictionary layer is local-first. OSWAP does not vendor multi-gigabyte dictionary databases into the core source repository. Instead, licensed source data is normalized into per-language JSONL indexes under `oswap-syntax/data/dictionaries/` and queried by `Invoke-OSWAPDictionary.ps1`.

The source manifest is `oswap-syntax/resources/dictionaries.json`. Every generated index should retain enough metadata to identify the upstream dataset, edition/dump date where available, licence, and attribution requirements.

Initial source adapters target Wiktionary/Wiktextract/Kaikki for broad multilingual coverage and JMdict for specialist Japanese multilingual lexicography. Source content is not relicensed as Apache-2.0 merely because the OSWAP integration code is Apache-2.0; dictionary data retains its upstream licence.

Dictionary lookup performs no network call by default and does not ask an LLM to invent a definition when a local source has no match.

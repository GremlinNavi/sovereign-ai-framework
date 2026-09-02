# `twin` and `twin=<PEMDAS>`

`twin` is OSWAP's explicit multi-destination publication command. It operates on the Git remote named `twin`, previews the current branch/status and configured push URLs, then requires explicit execution and confirmation before publication.

`twin=<PEMDAS>` adds expression-addressed selection. The expression is parsed locally using restricted arithmetic. Its positive integer result defines the required twin family size. The exact expression remains provenance data and is not discarded merely because another expression has the same result.

Example:

```text
twin=(9/3)
```

Resolution:

```text
raw_expression:        (9/3)
normalized_expression: (9/3)
expression_id:         l9d3r
family_value:          3
```

The dispatcher refuses expression-addressed execution unless the number of configured `twin` push URLs equals the resolved family value.

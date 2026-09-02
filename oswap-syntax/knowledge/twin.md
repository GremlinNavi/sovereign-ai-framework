# `upload twin=N` and `download twin=N`

OSWAP uses explicit transfer verbs for twin operations:

```text
oswap upload twin=N
oswap download twin=N
```

`N` may be an OSWAP arithmetic expression. The expression is parsed locally with the restricted OSWAP arithmetic grammar; arbitrary PowerShell evaluation is not used.

## Upload

`oswap upload twin=N` publishes the current committed Git state to selected destinations from the configured `twin` remote.

For upload, the resolved value may be fractional. A value such as `2.5` means two complete destination copies are guaranteed and there is a 50% probability of selecting one additional complete destination. Selection is without replacement.

Upload is preview-first. Execution requires `-Execute`, displays the selected destinations, and requires the operator to type `TWIN` before publication. Each successful destination is verified against the exact local HEAD SHA.

Example:

```text
oswap upload twin=(9/3)
```

resolves to three destination copies.

## Download

`oswap download twin=N` treats `N` as the number of independent twin sources that must agree before local integration is allowed.

Download factors must resolve to a whole number of at least two. Fractional values are rejected because probabilistic verification would weaken the consensus requirement.

Example:

```text
oswap download twin=(6/3)
```

resolves to:

```text
source_count: 2
consensus: unanimous
selection: configured-order
```

The implementation selects the first `N` configured twin source URLs in their explicit Git configuration order, fetches the requested branch from each source into temporary refs, and compares the resulting commit IDs.

The local branch is modified only when all selected sources report the same commit and that commit is a fast-forward from the current local HEAD. If the sources disagree, a source is unavailable, the worktree is dirty, or history has diverged, OSWAP halts without merge, rebase, reset, or implicit winner selection.

## Canonical spelling

Public OSWAP documentation uses `upload` and `download`. Legacy `push`/`pull` spellings may be accepted temporarily by compatibility layers, but they are not canonical OSWAP syntax.

# Contributing

Please open an issue before substantial changes. Contributions must be original work
that you have the right to submit under Apache-2.0, must not include personal data or
private research material, and should include focused tests where practical.

## Contribution rights

Every commit submitted for inclusion must be signed off under the
[Developer Certificate of Origin](DCO.md). Create signed-off commits with:

```bash
git commit -s -m "Describe the change"
```

The public CI workflow checks that every commit in a pull request has a
`Signed-off-by:` trailer. A DCO sign-off is a contributor certification, not a
cryptographic Git signature; maintainers may separately require verified commit or
tag signatures for release provenance.

Do not submit proprietary employer or client material, code copied from a source with
incompatible terms, secrets, personal data, or material whose publication could
compromise a pending patent decision. Copyright remains with each contributor unless
a separate written agreement says otherwise; submitted contributions are licensed as
provided by Apache-2.0. See [IP_POLICY.md](IP_POLICY.md) and
[TRADEMARKS.md](TRADEMARKS.md).

Run the locked test environment before proposing a release change:

```bash
pip install -r requirements-test.lock
pytest -q
```

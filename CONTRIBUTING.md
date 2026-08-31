# Contributing

Please open an issue before substantial changes. Contributions must be original work
that you have the right to submit under Apache-2.0 and should include focused tests.

Never include API keys, tokens, `.env` files, conversation history, research records,
personal data, or generated executable/release archives in a contribution. Report
security issues through [the security policy](SECURITY.md), not in a public issue.

## Local checks

Create a virtual environment, install the locked test set, and run the tests before
opening a pull request:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-test.lock
pytest -q
```

On Windows PowerShell, activate the environment with
`\.venv\Scripts\Activate.ps1`. Pull requests must keep the CI workflow green and
update documentation when behaviour or user-facing safety/privacy boundaries change.

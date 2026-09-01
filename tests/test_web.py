# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

import pytest

from app.web import validate_url


@pytest.mark.parametrize("url", [
    "file:///etc/passwd",
    "ftp://example.com/file",
    "javascript:alert(1)",
    "http://127.0.0.1:11434/api/tags",
    "http://localhost/",
    "http://192.168.1.10/",
    "http://[::1]/",
])
def test_unsafe_urls_rejected(url):
    with pytest.raises(ValueError):
        validate_url(url)


def test_credentials_rejected():
    with pytest.raises(ValueError):
        validate_url("https://user:pass@example.com/")

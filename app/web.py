# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

import re
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup

from .config import settings
from .security import validate_public_http_url

USER_AGENT = "EternalThread/0.4 (local research tool)"


def validate_url(url: str) -> None:
    validate_public_http_url(url)


def _read_limited(response: requests.Response, limit: int) -> str:
    chunks: list[bytes] = []
    total = 0
    for chunk in response.iter_content(chunk_size=8192):
        if not chunk:
            continue
        total += len(chunk)
        if total > limit:
            raise ValueError("Response exceeded configured size limit")
        chunks.append(chunk)
    return b"".join(chunks).decode(response.encoding or "utf-8", errors="replace")


def fetch_page(url: str) -> dict:
    validate_url(url)
    current = url
    for _ in range(settings.max_redirects + 1):
        validate_url(current)
        response = requests.get(
            current,
            headers={"User-Agent": USER_AGENT},
            timeout=settings.request_timeout,
            allow_redirects=False,
            stream=True,
        )
        if response.is_redirect or response.is_permanent_redirect:
            location = response.headers.get("location")
            response.close()
            if not location:
                raise ValueError("Redirect response did not provide a location")
            current = urljoin(current, location)
            validate_url(current)
            continue
        response.raise_for_status()
        content_type = response.headers.get("content-type", "").lower()
        if "text/html" not in content_type and "text/plain" not in content_type:
            response.close()
            raise ValueError(f"Unsupported content type: {content_type}")
        text_html = _read_limited(response, settings.max_web_response_bytes)
        final_url = response.url
        response.close()
        validate_url(final_url)
        soup = BeautifulSoup(text_html, "html.parser")
        for tag in soup(["script", "style", "noscript", "svg", "iframe", "object", "embed"]):
            tag.decompose()
        title = soup.title.get_text(" ", strip=True) if soup.title else final_url
        text = re.sub(r"\s+", " ", soup.get_text(" ", strip=True))
        return {"url": final_url, "title": title, "text": text[: settings.max_fetch_chars]}
    raise ValueError("Too many redirects")


def search_web(query: str, max_results: int | None = None) -> list[dict]:
    """Search DuckDuckGo's public HTML results page.

    Search results are untrusted external data. The caller must validate a result
    URL before handing it to fetch_page.
    """
    query = query.strip()
    if not query or len(query) > settings.max_search_query_chars:
        raise ValueError("Search query is empty or too long")
    max_results = max_results or settings.max_web_results
    response = requests.get(
        "https://html.duckduckgo.com/html/",
        params={"q": query},
        headers={"User-Agent": USER_AGENT},
        timeout=settings.request_timeout,
        stream=True,
    )
    response.raise_for_status()
    html = _read_limited(response, settings.max_search_response_bytes)
    response.close()
    soup = BeautifulSoup(html, "html.parser")
    results = []
    for node in soup.select(".result")[:max_results]:
        a = node.select_one("a.result__a")
        snippet = node.select_one(".result__snippet")
        if not a or not a.get("href"):
            continue
        url = urljoin("https://duckduckgo.com/", a["href"])
        try:
            validate_url(url)
        except ValueError:
            continue
        results.append({
            "title": a.get_text(" ", strip=True),
            "url": url,
            "snippet": snippet.get_text(" ", strip=True) if snippet else "",
        })
    return results

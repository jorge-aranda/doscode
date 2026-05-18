"""LLM provider adapters for DOSCODE.

The MVP keeps dependencies optional. OpenAI-compatible endpoints are handled
with the Python standard library so the proxy can run on old laptops and small
Raspberry Pi boards. Claude/OpenRouter/Ollama are selected by environment.
"""

from __future__ import annotations

import json
import os
import time
import urllib.request
from collections.abc import Iterator


SYSTEM_PROMPT = """You are DOSCODE, an AI coding agent for real MS-DOS.
Be concise, stream progress, and use simple tool tags only when useful:
<READ path=\"FILE\">, <WRITE path=\"FILE\">... </WRITE>, and <RUN>...</RUN>.
Never emit complex JSON for the DOS client."""


class LLMClient:
    """Small provider facade selected by `LLM_PROVIDER`."""

    _DEFAULT_MODELS = {
        "openai": "gpt-4o-mini",
        "openrouter": "openai/gpt-4o-mini",
        "claude": "claude-3-5-haiku-20241022",
        "ollama": "llama3.2",
    }

    def __init__(self) -> None:
        self.provider = os.getenv("LLM_PROVIDER", "mock").lower()
        default_model = self._DEFAULT_MODELS.get(self.provider, "gpt-4o-mini")
        self.model = os.getenv("LLM_MODEL", default_model)
        self.api_key = os.getenv("LLM_API_KEY", "")
        self.base_url = os.getenv("LLM_BASE_URL", "")

    def stream(self, prompt: str) -> Iterator[str]:
        """Yield assistant text progressively."""

        if self.provider in {"openai", "openrouter"}:
            yield from self._openai_compatible(prompt)
        elif self.provider == "claude":
            yield from self._claude(prompt)
        elif self.provider == "ollama":
            yield from self._ollama(prompt)
        else:
            yield from self._mock(prompt)

    def _mock(self, prompt: str) -> Iterator[str]:
        yield "analyzing request..."
        time.sleep(0.05)
        upper = prompt.upper()
        if upper.startswith("/READ "):
            yield f"<READ path=\"{prompt[6:].strip()}\">"
        elif upper.startswith("/RUN "):
            yield "<RUN>"
            yield prompt[5:].strip()
            yield "</RUN>"
        else:
            yield "ready to inspect files or run commands."
            yield "try /read BUILD.BAT or /fix CONFIG.SYS."

    def _openai_compatible(self, prompt: str) -> Iterator[str]:
        base = self.base_url or (
            "https://openrouter.ai/api/v1" if self.provider == "openrouter" else "https://api.openai.com/v1"
        )
        payload = {
            "model": self.model,
            "stream": False,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
        }
        data = self._post_json(f"{base}/chat/completions", payload)
        content = data["choices"][0]["message"]["content"]
        yield from self._chunk_lines(content)

    def _claude(self, prompt: str) -> Iterator[str]:
        base = self.base_url or "https://api.anthropic.com/v1"
        payload = {
            "model": self.model,
            "max_tokens": 1024,
            "system": SYSTEM_PROMPT,
            "messages": [{"role": "user", "content": prompt}],
        }
        data = self._post_json(
            f"{base}/messages",
            payload,
            auth=False,
            extra_headers={
                "anthropic-version": "2023-06-01",
                "x-api-key": self.api_key,
            },
        )
        text = "\n".join(part.get("text", "") for part in data.get("content", []) if part.get("type") == "text")
        yield from self._chunk_lines(text)

    def _ollama(self, prompt: str) -> Iterator[str]:
        base = self.base_url or "http://127.0.0.1:11434"
        payload = {
            "model": self.model,
            "stream": False,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
        }
        data = self._post_json(f"{base}/api/chat", payload, auth=False)
        yield from self._chunk_lines(data.get("message", {}).get("content", ""))

    def _post_json(
        self,
        url: str,
        payload: dict,
        *,
        auth: bool = True,
        extra_headers: dict[str, str] | None = None,
    ) -> dict:
        headers = {"Content-Type": "application/json"}
        if auth and self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        if extra_headers:
            headers.update(extra_headers)
        request = urllib.request.Request(url, data=json.dumps(payload).encode(), headers=headers, method="POST")
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode())

    @staticmethod
    def _chunk_lines(text: str) -> Iterator[str]:
        for raw in text.splitlines() or [text]:
            line = raw.strip()
            if line:
                yield line

"""DOSCODE plain text serial protocol.

The DOS side is intentionally tiny: prompts are sent as two text lines and the
proxy streams one `LINE ...` record at a time, followed by `END`.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, TextIO


@dataclass(slots=True)
class Prompt:
    """A user request received from the DOS client."""

    text: str
    declared_length: int | None = None


def read_prompt(stream: TextIO) -> Prompt | None:
    """Read one `PROMPT n` frame from a text stream."""

    header = stream.readline()
    if not header:
        return None
    header = header.strip()
    if not header.startswith("PROMPT"):
        return Prompt(text=header)

    parts = header.split(maxsplit=1)
    declared = int(parts[1]) if len(parts) == 2 and parts[1].isdigit() else None
    text = stream.readline().rstrip("\r\n")
    return Prompt(text=text, declared_length=declared)


def encode_line(text: str) -> str:
    """Encode one streamed response line for the DOS client."""

    return f"LINE {text}\r\n"


def encode_end() -> str:
    """Encode the end marker for one assistant turn."""

    return "END\r\n"


def stream_response(lines: Iterable[str], output: TextIO) -> None:
    """Write a full streamed response."""

    for line in lines:
        output.write(encode_line(line))
        output.flush()
    output.write(encode_end())
    output.flush()

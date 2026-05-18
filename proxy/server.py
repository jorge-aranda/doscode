"""DOSCODE modern proxy.

Run this on Linux, macOS, Windows, or Raspberry Pi. It bridges a DOS serial
client to modern HTTPS LLM APIs while preserving a tiny text protocol.
"""

from __future__ import annotations

import argparse
import os
import sys
from contextlib import contextmanager
from typing import Iterator, TextIO

from llm import LLMClient
from protocol import read_prompt, stream_response


@contextmanager
def open_transport(port: str | None, baud: int) -> Iterator[tuple[TextIO, TextIO]]:
    """Open serial transport, or stdin/stdout for development."""

    if not port or port == "stdio":
        yield sys.stdin, sys.stdout
        return

    try:
        import serial  # type: ignore
    except ImportError as exc:
        raise SystemExit("pyserial is required for SERIAL_PORT. Install with: python -m pip install pyserial") from exc

    ser = serial.Serial(port=port, baudrate=baud, bytesize=8, parity="N", stopbits=1, timeout=None)
    try:
        text_in = ser
        reader = TextSerialReader(text_in)
        writer = TextSerialWriter(text_in)
        yield reader, writer
    finally:
        ser.close()


class TextSerialReader:
    """Tiny text wrapper around a pyserial byte stream."""

    def __init__(self, serial_obj) -> None:
        self.serial = serial_obj

    def readline(self) -> str:
        return self.serial.readline().decode("cp437", errors="replace")


class TextSerialWriter:
    """Tiny text writer around a pyserial byte stream."""

    def __init__(self, serial_obj) -> None:
        self.serial = serial_obj

    def write(self, text: str) -> int:
        data = text.encode("cp437", errors="replace")
        return self.serial.write(data)

    def flush(self) -> None:
        self.serial.flush()


def serve(input_stream: TextIO, output_stream: TextIO) -> None:
    """Serve prompts forever."""

    llm = LLMClient()
    while True:
        prompt = read_prompt(input_stream)
        if prompt is None:
            break
        if not prompt.text:
            continue
        lines = list(llm.stream(prompt.text))
        print(f"[llm] {lines}", file=sys.stderr, flush=True)
        stream_response(iter(lines), output_stream)


def main() -> int:
    parser = argparse.ArgumentParser(description="DOSCODE serial-to-LLM proxy")
    parser.add_argument("--serial-port", default=os.getenv("SERIAL_PORT", "stdio"))
    parser.add_argument("--baud", type=int, default=int(os.getenv("SERIAL_BAUD", "9600")))
    args = parser.parse_args()

    with open_transport(args.serial_port, args.baud) as (reader, writer):
        serve(reader, writer)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

# DOSCODE

DOSCODE is a retro AI coding agent for real DOS machines. It is inspired by
modern terminal coding agents, but the client is built for MS-DOS, FreeDOS,
DOSBox, and 8086/286/386/486/Pentium-era hardware.

The goal is simple: feel like a fast 1994 hacker tool that can talk to modern
LLMs through a serial cable.

## Architecture

DOSCODE has two parts:

```text
MS-DOS client  <--- plain text serial --->  modern Python proxy  <--- HTTPS --->  LLM provider
```

### DOS client

Location: `client/`

The DOS client is written in QuickBasic/QBasic-style BASIC and is responsible
for the local experience:

- 80x25 text UI using `SCREEN 0`
- CP437-style boxes and ANSI-era colors
- fixed input line at the bottom
- streamed chat area above the prompt
- local commands
- file reads and writes
- confirmed DOS command execution
- plain text serial communication over `COM1`/`COM2`

The DOS client deliberately avoids HTTPS, TLS, heavy JSON, and modern runtime
dependencies.

To build the DOS client, you need QuickBasic 4.5 compiler tools such as
`BC.EXE` and `LINK.EXE`. These tools are not included with MS-DOS, FreeDOS, or
DOSBox; they must be installed separately in the DOS environment. See
`docs/build.md` for the full build and DOSBox notes.

### Modern proxy

Location: `proxy/`

The proxy is written in Python 3 and runs on Linux, Windows, macOS, or a
Raspberry Pi. It handles modern networking and provider APIs:

- OpenAI-compatible chat completions
- Claude Messages API
- OpenRouter
- Ollama
- serial transport through `pyserial`
- local development over `stdio`
- progressive line-by-line streaming to the DOS client

## Current MVP

The current MVP implements the first target milestone:

- opens the DOS TUI
- draws a retro 80x25 frame
- connects to `COM1`
- sends prompts to the proxy
- receives streamed `LINE ...` responses
- displays AI responses progressively
- supports `/read`, `/run`, `/model`, `/clear`, `/help`, and `/exit`
- includes parser hooks for `<READ>`, `<WRITE>`, and `<RUN>` tool actions
- asks for confirmation before `RUN`

The next milestones are richer history, diff navigation, undo state, file
browser navigation, and fully automated multi-line `<WRITE>` application.

## User interface

The client targets an 80x25 text screen:

```text
┌ DOSCODE ───────────────────────────────────────────────────────────────────┐
│ model: gpt-5.5        path: C:\WORK                                      │
├────────────────────────────────────────────────────────────────────────────┤
│ AI  > DOSCODE ready. Proxy expected on COM1. Press F1 for help.           │
│ You > fix BUILD.BAT                                                       │
│ AI  > analyzing request...                                                │
│ ◆ READ BUILD.BAT                                                          │
│ ✓ read 28 lines                                                           │
├────────────────────────────────────────────────────────────────────────────┤
│ > _                                                                        │
│ F1 Help  F2 Files  F3 Retry  F4 Clear  F5 Model  TAB Commands             │
└────────────────────────────────────────────────────────────────────────────┘
```

Colors are classic DOS colors:

- black background
- gray normal text
- green AI text
- yellow user text
- cyan titles
- red errors
- magenta actions

## Commands

Implemented or reserved commands:

```text
/help
/clear
/history
/model MODEL_NAME
/exit
/read FILE
/write FILE
/run COMMAND
/fix FILE
/explain FILE
/plan TASK
/apply
/diff
/undo
```

Examples:

```text
/read AUTOEXEC.BAT
/run DIR
/fix CONFIG.SYS
```

`/run` always asks for confirmation on the DOS side before executing a command.

## Serial protocol

The protocol is line-oriented text. It is intentionally simple enough for DOS:

Client to proxy:

```text
PROMPT 24
fix BUILD.BAT
```

Proxy to client:

```text
LINE I will inspect the file
LINE <READ path="BUILD.BAT">
LINE found a bad PATH entry
LINE <WRITE path="BUILD.BAT">
END
```

See `docs/protocol.md` for details.

## Requirements

### DOS client

- MS-DOS, FreeDOS, or DOSBox
- QuickBasic 4.5 toolchain for building (`BC.EXE` and `LINK.EXE`)
- 640 KB conventional-memory target
- `SCREEN 0` text mode
- serial connection mapped to `COM1` or `COM2`

### Proxy

- Python 3.10+
- `pyserial` when using a real serial port
- network access for hosted LLM providers
- provider API key when required

Install proxy dependencies:

```sh
python3 -m pip install -r proxy/requirements.txt
```

## Configuration

Environment variables:

```text
LLM_PROVIDER=openai|claude|openrouter|ollama|mock
LLM_MODEL=gpt-5.5
LLM_API_KEY=your-api-key
LLM_BASE_URL=optional-compatible-base-url
SERIAL_PORT=/dev/ttyUSB0 or COM3 or stdio
SERIAL_BAUD=9600
```

For local development without serial hardware, use the mock provider and stdio:

```sh
cd proxy
LLM_PROVIDER=mock SERIAL_PORT=stdio python3 server.py
```

Then type a protocol frame manually:

```text
PROMPT 15
/read BUILD.BAT
```

## Building the DOS client

Inside DOS, FreeDOS, or DOSBox with QuickBasic tools in `PATH`:

```bat
CD CLIENT
BUILD.BAT
RUN.BAT
```

See `docs/build.md` for DOSBox and serial-port notes.

## Project layout

```text
client/
    doscode.bas
    ui.bas
    serial.bas
    parser.bas
    files.bas
    BUILD.BAT
    RUN.BAT
proxy/
    server.py
    llm.py
    protocol.py
    requirements.txt
docs/
    protocol.md
    build.md
README.md
AGENTS.md
LICENSE
```

## License

DOSCODE is distributed under the Apache License 2.0. See `LICENSE`.

# Building DOSCODE

## Proxy setup

Install Python dependencies on the modern machine:

```sh
python3 -m pip install -r proxy/requirements.txt
```

Run the proxy with a real serial port:

```sh
cd proxy
LLM_PROVIDER=openai \
LLM_MODEL=gpt-5.5 \
LLM_API_KEY=your-key \
SERIAL_PORT=/dev/ttyUSB0 \
python3 server.py
```

On Windows:

```bat
CD proxy
SET LLM_PROVIDER=openai
SET LLM_MODEL=gpt-5.5
SET LLM_API_KEY=your-key
SET SERIAL_PORT=COM3
python server.py --serial-port %SERIAL_PORT%
```

For development without serial hardware:

```sh
cd proxy
LLM_PROVIDER=mock SERIAL_PORT=stdio python3 server.py
```

## Proxy environment variables

All proxy configuration is done through environment variables:

| Variable | Required | Default | Description |
|---|---|---|---|
| `LLM_PROVIDER` | no | `mock` | Provider: `openai`, `openrouter`, `claude`, `ollama`, or `mock` |
| `LLM_MODEL` | no | `gpt-5.5` | Model name passed to the provider |
| `LLM_API_KEY` | see below | _(empty)_ | API key for cloud providers |
| `LLM_BASE_URL` | no | _(provider default)_ | Override the provider API base URL |
| `SERIAL_PORT` | no | _(none)_ | Serial device (e.g. `/dev/ttyUSB0`, `COM3`) or `stdio` for development |

### API key requirements by provider

| `LLM_PROVIDER` | API key needed | Where to get it |
|---|---|---|
| `openai` | yes | https://platform.openai.com/api-keys |
| `openrouter` | yes | https://openrouter.ai/keys |
| `claude` | yes | https://console.anthropic.com/settings/keys |
| `ollama` | no | runs locally, no key needed |
| `mock` | no | test mode, no network calls |

### Examples

OpenAI:

```sh
cd proxy
LLM_PROVIDER=openai \
LLM_MODEL=gpt-4o \
LLM_API_KEY=sk-... \
SERIAL_PORT=/dev/ttyUSB0 \
python3 server.py
```

Claude:

```sh
cd proxy
LLM_PROVIDER=claude \
LLM_MODEL=claude-opus-4-5 \
LLM_API_KEY=sk-ant-... \
SERIAL_PORT=/dev/ttyUSB0 \
python3 server.py
```

Ollama (local, no key):

```sh
cd proxy
LLM_PROVIDER=ollama \
LLM_MODEL=llama3 \
SERIAL_PORT=/dev/ttyUSB0 \
python3 server.py
```

Mock mode (no hardware, no key):

```sh
cd proxy
LLM_PROVIDER=mock SERIAL_PORT=stdio python3 server.py
```

## DOS client build

Requirements:

- DOS, FreeDOS, or DOSBox
- QuickBasic 4.5 compiler tools in `PATH`
- QuickBasic 4.5 runtime libraries available through the DOS `LIB` variable
- the `client/` directory copied or mounted inside DOS

QuickBasic 4.5 is not included with MS-DOS, FreeDOS, or DOSBox. It is a
separate compiler package that must be installed or provided inside the DOS
environment before building DOSCODE. The build script expects these tools to be
available in the DOS `PATH`:

- `BC.EXE`, the QuickBasic compiler
- `LINK.EXE`, the DOS linker

The linker also needs the QuickBasic runtime library directory. In a typical
QuickBasic 4.5 installation this directory contains `BCOM45.LIB`. If `LINK.EXE`
prints this warning:

```text
LINK: warning L4051: BCOM45.LIB : cannot find library
```

then `LINK.EXE` is running, but it cannot find the QuickBasic runtime library.
Set the DOS `LIB` environment variable to the directory where `BCOM45.LIB` is
installed before running `BUILD.BAT`. Example:

```bat
SET PATH=C:\QB45;%PATH%
SET LIB=C:\QB45\LIB;%LIB%
```

Some QuickBasic 4.5 installations place `BCOM45.LIB` directly in `C:\QB45`
instead of `C:\QB45\LIB`. In that case use:

```bat
SET LIB=C:\QB45;%LIB%
```

The `QBASIC.EXE` interpreter included with some MS-DOS versions is useful for
editing or running simple BASIC programs, but it is not enough to build the
standalone `DOSCODE.EXE` produced by `client/BUILD.BAT`.

The BASIC sources, batch files, and QuickBasic project file in `client/` are
kept as plain ASCII files with DOS `CRLF` line endings, no UTF-8 byte order
mark, and a final DOS end-of-file marker (`Ctrl+Z`, byte `0x1A`). This is
important because some DOS versions of QuickBasic do not parse Unix `LF` line
endings, BOM prefixes, extended text encodings, or missing DOS EOF markers
correctly.

For the QuickBasic IDE, `client/DOSCODE.MAK` lists the program modules:

```text
DOSCODE.BAS
UI.BAS
SERIAL.BAS
PARSER.BAS
FILES.BAS
```

Open that project file from QuickBasic when you want to run or inspect the
multi-module client inside the IDE.

Build:

```bat
CD CLIENT
BUILD.BAT
```

Run:

```bat
RUN.BAT
```

## DOSBox serial example

DOSBox can map a host serial device to a DOS `COM` port. Exact syntax depends
on the DOSBox build and host OS. A common pattern is:

```ini
serial1=directserial realport:COM3
```

or on Unix-like hosts:

```ini
serial1=directserial realport:/dev/ttyUSB0
```

Then the BASIC client can use `COM1` from inside DOSBox.

## Notes for vintage machines

- Keep baud rate conservative; `9600` is the default.
- Avoid large prompts and large file reads in the DOS client.
- The DOS side should stay line-oriented and RAM-friendly.
- The proxy owns HTTPS, provider APIs, and heavy context management.

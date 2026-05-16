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

## DOS client build

Requirements:

- DOS, FreeDOS, or DOSBox
- QuickBasic 4.5 compiler tools in `PATH`
- the `client/` directory copied or mounted inside DOS

QuickBasic 4.5 is not included with MS-DOS, FreeDOS, or DOSBox. It is a
separate compiler package that must be installed or provided inside the DOS
environment before building DOSCODE. The build script expects these tools to be
available in the DOS `PATH`:

- `BC.EXE`, the QuickBasic compiler
- `LINK.EXE`, the DOS linker

The `QBASIC.EXE` interpreter included with some MS-DOS versions is useful for
editing or running simple BASIC programs, but it is not enough to build the
standalone `DOSCODE.EXE` produced by `client/BUILD.BAT`.

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

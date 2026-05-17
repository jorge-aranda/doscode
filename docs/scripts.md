# DOSCODE Scripts

Helper scripts for development, debugging, and serial port monitoring.

## scripts/monitor_serial.sh

Taps the serial traffic between the Python proxy and the DOSBox client in real
time. It uses `socat` to create two linked PTYs and prints every byte that
flows in each direction to the terminal, labelled with `[proxy->dos]` or
`[dos->proxy]`. Traffic is also saved to separate log files.

### Requirements

- `socat` — install with `brew install socat` (macOS) or `apt install socat`
  (Debian/Ubuntu).

### Usage

```sh
./scripts/monitor_serial.sh [PTY_PROXY] [PTY_DOSBOX] [LOG_DIR]
```

| Argument    | Default                  | Description                                      |
|-------------|--------------------------|--------------------------------------------------|
| `PTY_PROXY` | `/tmp/pty_proxy`         | PTY passed to the proxy via `--serial-port`      |
| `PTY_DOSBOX`| `/tmp/pty_dosbox`        | PTY configured in DOSBox as the serial port      |
| `LOG_DIR`   | `/tmp/doscode_monitor`   | Directory where log files are written            |

Log files created:

- `$LOG_DIR/proxy_to_dos.log` — bytes sent from the proxy to DOSBox
- `$LOG_DIR/dos_to_proxy.log` — bytes sent from DOSBox to the proxy

### Typical workflow

**Step 1 — Start the monitor** (creates the two PTYs):

```sh
./scripts/monitor_serial.sh
```

The script prints the PTY paths and waits. Keep this terminal open.

**Step 2 — Start the proxy** (in a second terminal):

```sh
python proxy/server.py --serial-port /tmp/pty_proxy
```

**Step 3 — Configure DOSBox** to use `/tmp/pty_dosbox` as `COM1`.

Edit your DOSBox config file (e.g. `~/.dosbox/dosbox-staging.conf` or
`~/Library/Preferences/DOSBox/dosbox-staging.conf`) and set:

```ini
[serial]
serial1 = nullmodem server:/tmp/pty_dosbox
```

Or with `directserial`:

```ini
[serial]
serial1 = directserial realport:/tmp/pty_dosbox
```

**Step 4 — Start DOSBox** and run the DOS client inside it.

**Step 5 — Watch the monitor terminal** for live traffic. Example output:

```
[proxy->dos] LINE I will inspect the file
[dos->proxy] PROMPT 18
[dos->proxy] fix CONFIG.SYS
[proxy->dos] LINE found a bad PATH entry
[proxy->dos] END
```

Press `Ctrl+C` to stop monitoring.

### Baud rate alignment

Make sure the baud rate matches on all three sides:

| Side          | Setting                                              |
|---------------|------------------------------------------------------|
| DOSBox config | `serial1 = nullmodem server:/tmp/pty_dosbox`         |
| Proxy         | `--baud 9600` (default)                              |
| DOS client    | `OPEN "COM1:9600,N,8,1,CD0,CS0,DS0,RS" AS #1`       |

### Verifying COM1 inside DOSBox

Inside DOSBox you can confirm that `COM1` is linked to the PTY with:

```
MODE COM1:9600,N,8,1
```

If the command returns no error, the port is active and connected.

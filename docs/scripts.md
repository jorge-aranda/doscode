# DOSCODE Scripts

Helper scripts for development, debugging, and serial port monitoring.

---

## scripts/monitor_serial.sh

Taps the serial traffic between DOSBox and the Python proxy in real time. It
replaces the plain `socat TCP-LISTEN:2323 <-> PTY` bridge of the validated
setup with a `socat -v` tap that prints every byte in each direction to the
terminal, labelled with `[proxy->dos]` or `[dos->proxy]`, and saves per-
direction log files.

### Requirements

- `socat` — install with `brew install socat` (macOS) or `apt install socat`
  (Debian/Ubuntu).

### Usage

```sh
./scripts/monitor_serial.sh [LISTEN_PORT] [PTY_PROXY] [LOG_DIR]
```

| Argument      | Default                  | Description                                                       |
|---------------|--------------------------|-------------------------------------------------------------------|
| `LISTEN_PORT` | `2323`                   | TCP port where DOSBox connects as `nullmodem` client              |
| `PTY_PROXY`   | `/tmp/pty_proxy`         | PTY passed to the proxy via `--serial-port`                       |
| `LOG_DIR`     | `/tmp/doscode_monitor`   | Directory where log files are written                             |

Log files created:

- `$LOG_DIR/proxy_to_dos.log` — bytes sent from the proxy to DOSBox
- `$LOG_DIR/dos_to_proxy.log` — bytes sent from DOSBox to the proxy

### Typical workflow

**Step 1 — Start the proxy** (against the PTY the script will create):

```sh
python3 proxy/server.py --serial-port /tmp/pty_proxy --baud 9600
```

**Step 2 — Start the monitor** (replaces the plain `socat` TCP↔PTY bridge):

```sh
./scripts/monitor_serial.sh
```

The script listens on TCP `2323`, exposes the proxy PTY at `/tmp/pty_proxy`,
and prints every byte in each direction. Keep this terminal open.

**Step 3 — Configure DOSBox** as a `nullmodem` TCP client. Edit your DOSBox
config file (e.g. `~/.dosbox/dosbox-staging.conf` or
`~/Library/Preferences/DOSBox/dosbox-staging.conf`) and set:

```ini
[serial]
serial1=nullmodem server:localhost port:2323 transparent:1 rxdelay:100
serial2=dummy
```

DOSBox `directserial realport:` against an arbitrary PTY path is **not**
supported on macOS and unreliable on Linux; do not use it for this bridge.

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

| Side          | Setting                                                              |
|---------------|----------------------------------------------------------------------|
| DOSBox config | `serial1=nullmodem server:localhost port:2323 transparent:1 rxdelay:100` |
| monitor_serial.sh | bridges `TCP-LISTEN:2323` ↔ `/tmp/pty_proxy` (replaces plain socat) |
| Proxy         | `--serial-port /tmp/pty_proxy --baud 9600`                           |
| DOS client    | `OPEN "COM1:9600,N,8,1,CD0,CS0,DS0,RS" AS #1`                        |

Alternative without the monitor tap (plain `socat` bridge):

- `socat -d -d pty,raw,echo=0,link=/tmp/pty_proxy TCP-LISTEN:2323,reuseaddr,fork &`

### Verifying COM1 inside DOSBox

Inside DOSBox you can confirm that `COM1` is linked to the PTY with:

```
MODE COM1:9600,N,8,1
```

If the command returns no error, the port is active and connected.

---

## scripts/link_dosbox_project.sh

Creates symlinks from a DOSBox-mounted directory back to the `client/` source
files in the project tree. This lets DOSBox see the latest source files without
copying them manually every time you edit them on the host.

### Requirements

No external dependencies beyond a POSIX shell and `ln`.

### Usage

```sh
./scripts/link_dosbox_project.sh [TARGET_DIR]
```

| Argument     | Default                                              | Description                                      |
|--------------|------------------------------------------------------|--------------------------------------------------|
| `TARGET_DIR` | `~/vm-projects/dos-box-programs/apps/doscode`        | Subdirectory inside the DOSBox-mounted drive where links are created |

The script iterates over every file directly inside `client/` and creates a
symlink in `TARGET_DIR` pointing back to the original source file. It skips
non-files (subdirectories) and any destination that already exists and is not a
symlink.

Output per file:

- `LINK <dst> -> <src>` — symlink created.
- `OK   <dst> -> <src>` — symlink already correct, nothing changed.
- `SKIP <dst> exists and is not a symlink` — destination is a real file; left
  untouched.

### Typical workflow

**Step 1 — Run the script once** from the project root:

```sh
./scripts/link_dosbox_project.sh
```

Or pass a custom target if your DOSBox mount point differs:

```sh
./scripts/link_dosbox_project.sh ~/dosbox/drives/c/doscode
```

**Step 2 — Configure DOSBox** to mount `TARGET_DIR` as drive `C:` (or any
drive). Example `dosbox-staging.conf`:

```ini
[autoexec]
mount c ~/vm-projects/dos-box-programs
c:
path=%PATH%;C:\apps\doscode
```

The DOSCODE files will be available at `C:\apps\doscode\` inside DOSBox.

**Step 3 — Edit source files** on the host as normal. Because the files in
`TARGET_DIR` are symlinks, DOSBox always sees the current version without any
extra copy step.

### Safety checks

The script refuses to create links if `TARGET_DIR` is inside the project tree
itself, to avoid accidental self-referential symlinks:

```
ERROR target must be outside the project tree: /path/to/project/client
```

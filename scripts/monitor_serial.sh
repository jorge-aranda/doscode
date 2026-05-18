#!/usr/bin/env bash
# monitor_serial.sh — Tap serial traffic between DOSBox (nullmodem TCP) and
# the Python proxy (PTY), printing every byte in each direction and saving
# per-direction logs.
#
# Usage:
#   ./scripts/monitor_serial.sh [LISTEN_PORT] [PTY_PROXY] [LOG_DIR]
#
# Defaults:
#   LISTEN_PORT = 2323                 (DOSBox connects here as nullmodem TCP client)
#   PTY_PROXY   = /tmp/pty_proxy       (PTY consumed by proxy/server.py --serial-port)
#   LOG_DIR     = /tmp/doscode_monitor
#
# Validated end-to-end flow:
#
#   DOS client
#       |  COM1
#       v
#   DOSBox  --nullmodem TCP-->  localhost:LISTEN_PORT
#                                       |
#                                       v
#                          this script (socat with -v tap)
#                                       |
#                                       v
#                                /tmp/pty_proxy
#                                       |
#                                       v
#                         python proxy/server.py --serial-port /tmp/pty_proxy
#
# DOSBox configuration (`dosbox.conf`):
#
#   [serial]
#   serial1=nullmodem server:localhost port:2323 transparent:1 rxdelay:100
#   serial2=dummy
#
# Typical workflow:
#   1. Start the proxy:  python proxy/server.py --serial-port /tmp/pty_proxy
#   2. Run this script (replaces the plain `socat ... TCP-LISTEN:2323 ...` bridge).
#   3. Start DOSBox and run the DOS client inside it.
#   4. Watch this terminal for live traffic; logs are saved in LOG_DIR.

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  awk '/^set -euo pipefail/{exit} /^#[^!]/{sub(/^# ?/,""); print}' "$0"
  exit 0
fi

LISTEN_PORT="${1:-2323}"
PTY_PROXY="${2:-/tmp/pty_proxy}"
LOG_DIR="${3:-/tmp/doscode_monitor}"

mkdir -p "$LOG_DIR"

LOG_P2D="$LOG_DIR/proxy_to_dos.log"
LOG_D2P="$LOG_DIR/dos_to_proxy.log"

# Remove stale PTY symlink from a previous run.
[ -e "$PTY_PROXY" ] && rm -f "$PTY_PROXY"

if ! command -v socat >/dev/null 2>&1; then
  echo "ERROR: socat is required. Install with 'brew install socat' or 'apt install socat'." >&2
  exit 1
fi

echo "============================================"
echo "  DOSCODE serial monitor (TCP <-> PTY tap)"
echo "============================================"
echo "  Listen TCP : localhost:$LISTEN_PORT  (DOSBox nullmodem client)"
echo "  Proxy PTY  : $PTY_PROXY              (proxy/server.py --serial-port)"
echo "  Logs       : $LOG_DIR"
echo "--------------------------------------------"
echo "  proxy->dos : $LOG_P2D"
echo "  dos->proxy : $LOG_D2P"
echo "============================================"
echo ""
echo "Start the proxy with:"
echo "  python proxy/server.py --serial-port $PTY_PROXY"
echo ""
echo "DOSBox dosbox.conf:"
echo "  serial1=nullmodem server:localhost port:$LISTEN_PORT transparent:1 rxdelay:100"
echo ""
echo "Press Ctrl+C to stop monitoring."
echo ""

# socat -v traces every transfer to stderr with a direction marker:
#   ">" = data flowing from the first address to the second (DOSBox -> proxy PTY)
#   "<" = data flowing from the second address back to the first (proxy PTY -> DOSBox)
# We bridge TCP-LISTEN:LISTEN_PORT <-> PTY,link=$PTY_PROXY so DOSBox can connect
# as a nullmodem TCP client while the proxy keeps reading the PTY as before.
socat \
  -v \
  "TCP-LISTEN:$LISTEN_PORT,reuseaddr,fork" \
  "PTY,link=$PTY_PROXY,raw,echo=0" \
  2>&1 | awk '
    /^>/ { dir="[dos->proxy]"; next_emit=1 }
    /^</ { dir="[proxy->dos]"; next_emit=1 }
    { print dir " " $0 }
  ' | tee >(grep -E "^\[proxy->dos\]" >> "$LOG_P2D") \
         >(grep -E "^\[dos->proxy\]" >> "$LOG_D2P") \
         /dev/stdout

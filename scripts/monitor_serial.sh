#!/usr/bin/env bash
# monitor_serial.sh — Tap serial traffic between the proxy and DOSBox client.
#
# Usage:
#   ./scripts/monitor_serial.sh [PTY_PROXY] [PTY_DOSBOX] [LOG_DIR]
#
# Defaults:
#   PTY_PROXY  = /tmp/pty_proxy   (the PTY you pass to --serial-port)
#   PTY_DOSBOX = /tmp/pty_dosbox  (the PTY you configure in DOSBox)
#   LOG_DIR    = /tmp/doscode_monitor
#
# How it works:
#   socat creates two linked PTYs and a bidirectional tap using tee so that
#   every byte flowing in each direction is written to a log file AND printed
#   to the terminal with a direction prefix (>>> proxy->dos, <<< dos->proxy).
#
# Typical workflow:
#   1. Run this script first — it prints the two PTY paths to use.
#   2. Start the proxy:  python proxy/server.py --serial-port /tmp/pty_proxy
#   3. Configure DOSBox: serial1=modem realport:/tmp/pty_dosbox  (or nullmodem)
#   4. Run the DOS client inside DOSBox.
#   5. Watch this terminal for live traffic; logs are saved in LOG_DIR.

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  awk '/^set -euo pipefail/{exit} /^#[^!]/{sub(/^# ?/,""); print}' "$0"
  exit 0
fi

PTY_PROXY="${1:-/tmp/pty_proxy}"
PTY_DOSBOX="${2:-/tmp/pty_dosbox}"
LOG_DIR="${3:-/tmp/doscode_monitor}"

mkdir -p "$LOG_DIR"

LOG_P2D="$LOG_DIR/proxy_to_dos.log"
LOG_D2P="$LOG_DIR/dos_to_proxy.log"

# Remove stale symlinks from a previous run.
[ -e "$PTY_PROXY" ]  && rm -f "$PTY_PROXY"
[ -e "$PTY_DOSBOX" ] && rm -f "$PTY_DOSBOX"

echo "============================================"
echo "  DOSCODE serial monitor"
echo "============================================"
echo "  Proxy PTY  : $PTY_PROXY"
echo "  DOSBox PTY : $PTY_DOSBOX"
echo "  Logs       : $LOG_DIR"
echo "--------------------------------------------"
echo "  proxy->dos : $LOG_P2D"
echo "  dos->proxy : $LOG_D2P"
echo "============================================"
echo ""
echo "Start the proxy with:"
echo "  python proxy/server.py --serial-port $PTY_PROXY"
echo ""
echo "Configure DOSBox serial port to: $PTY_DOSBOX"
echo ""
echo "Press Ctrl+C to stop monitoring."
echo ""

# socat links the two PTYs and tees each direction to a log file.
# The SYSTEM() call prints each byte-chunk to stdout with a direction arrow.
socat \
  -v \
  "PTY,link=$PTY_PROXY,raw,echo=0" \
  "PTY,link=$PTY_DOSBOX,raw,echo=0" \
  2>&1 | awk '
    /^>/ { dir="[proxy->dos]" }
    /^</ { dir="[dos->proxy]" }
    { print dir " " $0 }
  ' | tee >(grep -E "^\[proxy->dos\]" >> "$LOG_P2D") \
         >(grep -E "^\[dos->proxy\]" >> "$LOG_D2P") \
         /dev/stdout

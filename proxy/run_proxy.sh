#!/usr/bin/env sh
set -eu
python3 server.py --serial-port "${SERIAL_PORT:-stdio}"

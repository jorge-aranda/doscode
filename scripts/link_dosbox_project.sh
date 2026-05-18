#!/usr/bin/env bash
# Create symlinks from a DOSBox-mounted app directory back to client files.
# Default target: ${HOME}/vm-projects/dos-box-programs/apps/doscode

set -euo pipefail

DEFAULT_TARGET_DIR="${HOME}/vm-projects/dos-box-programs/apps/doscode"
TARGET_DIR_INPUT="${1:-${DEFAULT_TARGET_DIR}}"
case "${TARGET_DIR_INPUT}" in
  "~") TARGET_DIR="${HOME}" ;;
  "~/"*) TARGET_DIR="${HOME}/${TARGET_DIR_INPUT:2}" ;;
  *) TARGET_DIR="${TARGET_DIR_INPUT}" ;;
esac
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="$(mkdir -p "${TARGET_DIR}" && cd "${TARGET_DIR}" && pwd)"

case "${TARGET_DIR}" in
  "${PROJECT_ROOT}"|"${PROJECT_ROOT}"/*)
    printf 'ERROR target must be outside the project tree: %s\n' "${TARGET_DIR}" >&2
    exit 1
    ;;
esac

mkdir -p "${TARGET_DIR}"

cd "${PROJECT_ROOT}"

# Link only files that live directly inside client/. Ignored build outputs and
# non-client project files are deliberately skipped.
for src in "${PROJECT_ROOT}"/client/*; do
  [ -f "${src}" ] || continue

  dst="${TARGET_DIR}/$(basename "${src}")"

  mkdir -p "$(dirname "${dst}")"

  if [ -L "${dst}" ]; then
    current_target="$(readlink "${dst}")"
    if [ "${current_target}" = "${src}" ]; then
      printf 'OK   %s -> %s\n' "${dst}" "${src}"
      continue
    fi
    rm "${dst}"
  elif [ -e "${dst}" ]; then
    printf 'SKIP %s exists and is not a symlink\n' "${dst}" >&2
    continue
  fi

  ln -s "${src}" "${dst}"
  printf 'LINK %s -> %s\n' "${dst}" "${src}"
done

printf '\nDOSBox project links are ready in: %s\n' "${TARGET_DIR}"

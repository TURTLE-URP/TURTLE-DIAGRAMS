#!/usr/bin/env bash
# Shared helpers for diagram build scripts.

ensure_dir_for() {
  local file="$1"
  mkdir -p "$(dirname "$file")"
}

log_ok() {
  echo "✔ $*"
}

log_err() {
  echo "✖ $*" >&2
}

require_cmd() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_err "Required command not found: $cmd"
    if [[ -n "$hint" ]]; then
      log_err "$hint"
    fi
    return 1
  fi
}

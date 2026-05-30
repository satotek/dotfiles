#!/usr/bin/env bash
# One-shot system-level Nix daemon bootstrap.
#
# Ensures the multi-user nix-daemon trusts extra binary caches declared by
# flakes we depend on (notably llm-agents.nix -> cache.numtide.com for the
# codex Rust package). Without this, those flakes' nixConfig.extra-substituters
# is ignored ("ignoring untrusted flake configuration setting") and codex is
# rebuilt from source with cargo on every switch.
#
# Idempotent: re-running is safe; existing matching lines are left alone.
# Run once per machine:
#   sudo nix/scripts/bootstrap-system-nix.sh
#
# On macOS we use nix-darwin's environment.etc."nix/nix.custom.conf" instead,
# so this script is Linux-only.

set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script is Linux-only. On macOS, nix-darwin manages nix.custom.conf." >&2
  exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Re-running with sudo..." >&2
  exec sudo "$0" "$@"
fi

conf=/etc/nix/nix.conf
mkdir -p /etc/nix
touch "$conf"

declare -a lines=(
  "extra-substituters = https://cache.numtide.com"
  "extra-trusted-substituters = https://cache.numtide.com"
  "extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
)

changed=0
for line in "${lines[@]}"; do
  if ! grep -qxF -- "$line" "$conf"; then
    printf '%s\n' "$line" >> "$conf"
    changed=1
  fi
done

if [[ "$changed" -eq 0 ]]; then
  echo "nix.conf already up to date; skipping daemon restart."
  exit 0
fi

echo "Updated $conf. Restarting nix-daemon so it picks up the new config..."
if /usr/bin/systemctl restart nix-daemon.service 2>/dev/null \
  || systemctl restart nix-daemon.service 2>/dev/null; then
  echo "nix-daemon restarted via systemd."
  exit 0
fi

# Fallback: signal the running daemon directly.
if pid=$(pidof nix-daemon 2>/dev/null) && [[ -n "$pid" ]]; then
  kill -TERM $pid
  echo "Sent SIGTERM to nix-daemon (pid $pid); it will be respawned by its supervisor."
else
  echo "Could not locate nix-daemon to restart. Restart it manually." >&2
  exit 1
fi

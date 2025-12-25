#!/bin/bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS_TYPE="$(uname -s)"

case "$OS_TYPE" in
  Darwin)
    echo "🍎 Detected macOS"
    "${SCRIPT_DIR}/install-deps-macos.sh"
    ;;
  Linux)
    echo "🐧 Detected Linux"
    "${SCRIPT_DIR}/install-deps-linux.sh"
    ;;
  *)
    echo "❌ Unsupported OS: $OS_TYPE"
    exit 1
    ;;
esac

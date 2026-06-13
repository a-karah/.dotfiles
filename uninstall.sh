#!/bin/bash
# Dotfiles uninstaller for macOS / Linux / WSL.
# Removes the symlinks/settings install.sh created (restoring any .bak backups);
# installed packages are left in place.
# Usage: ./uninstall.sh [--dry-run]
#
# Thin wrapper over `install.sh --uninstall`, which holds the shared link-map
# traversal and platform logic — kept here as a discoverable entry point.

set -euo pipefail
exec "$(cd "$(dirname "$0")" && pwd)/install.sh" --uninstall "$@"

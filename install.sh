#!/usr/bin/env bash
# Install or sync second-look into your global Claude Code config.
#
#   ./install.sh              install, or update an existing install
#   ./install.sh --uninstall  remove it
#
# Safe to re-run. Copies three files into ~/.claude and touches nothing else.
# A file that differs from the repo copy is backed up with a timestamp first.

if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# source in repo : target under $CLAUDE_DIR
FILES=(
  ".claude/agents/reviewer.md:agents/reviewer.md"
  ".claude/agents/devils-advocate.md:agents/devils-advocate.md"
  "CLAUDE.md:rules/second-look.md"
)

warn_legacy() {
  local old="$CLAUDE_DIR/CLAUDE.md"
  if [[ -f "$old" ]] && grep -qF "second-look" "$old"; then
    echo "warning: $old still contains second-look rules from an older install." >&2
    echo "         Delete that section by hand so the rules don't load twice." >&2
  fi
}

install() {
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  for pair in "${FILES[@]}"; do
    src="$REPO_DIR/${pair%%:*}"
    target="$CLAUDE_DIR/${pair#*:}"
    mkdir -p "$(dirname "$target")"
    if [[ -f "$target" ]] && cmp -s "$src" "$target"; then
      echo "current  $target"
      continue
    elif [[ -f "$target" ]]; then
      cp "$target" "$target.bak-$stamp"
      echo "updated  $target (old copy saved as $(basename "$target").bak-$stamp)"
    else
      echo "added    $target"
    fi
    cp "$src" "$target"
  done
  warn_legacy
}

uninstall() {
  for pair in "${FILES[@]}"; do
    target="$CLAUDE_DIR/${pair#*:}"
    if [[ -f "$target" ]]; then
      rm "$target"
      echo "removed  $target"
    fi
  done
  warn_legacy
}

case "${1:-}" in
  "") install ;;
  --uninstall) uninstall ;;
  *) echo "usage: ./install.sh [--uninstall]" >&2; exit 2 ;;
esac

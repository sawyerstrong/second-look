#!/usr/bin/env bash
# Install or sync second-look into your global Claude Code config.
#
#   ./install.sh              install, or update an existing install
#   ./install.sh --uninstall  remove it (leaves Claude Code and system packages)
#
# Safe to re-run. First installs anything missing: on Debian/Ubuntu (including
# ChromeOS Linux), the apt packages below; then Claude Code itself. Then copies
# four files into ~/.claude and touches nothing else there. A file that differs
# from the repo copy is backed up with a timestamp first.

if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# source in repo : target under $CLAUDE_DIR
FILES=(
  ".claude/agents/reviewer.md:agents/reviewer.md"
  ".claude/agents/devils-advocate.md:agents/devils-advocate.md"
  "CLAUDE.md:rules/second-look.md"
  "templates/analysis.md:second-look/analysis-template.md"
)

APT_PACKAGES=(
  curl git unzip python3 python3-pandas python3-scipy python3-statsmodels
  python3-matplotlib python3-openpyxl
)

ensure_packages() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "note     no apt-get here; make sure these are installed: ${APT_PACKAGES[*]}"
    return
  fi
  local missing=()
  for pkg in "${APT_PACKAGES[@]}"; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    echo "current  system packages"
    return
  fi
  echo "installing system packages: ${missing[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing[@]}"
}

ensure_claude() {
  local bin_dir="$HOME/.local/bin"
  if command -v claude >/dev/null 2>&1 || [[ -x "$bin_dir/claude" ]]; then
    echo "current  Claude Code"
  else
    echo "installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
  fi
  if ! command -v claude >/dev/null 2>&1 && [[ -x "$bin_dir/claude" ]]; then
    local line='export PATH="$HOME/.local/bin:$PATH"'
    if ! grep -qxF "$line" "$HOME/.bashrc" 2>/dev/null; then
      echo "$line" >> "$HOME/.bashrc"
    fi
    NEED_NEW_SHELL=1
  fi
}

warn_legacy() {
  local old="$CLAUDE_DIR/CLAUDE.md"
  if [[ -f "$old" ]] && grep -qF "second-look" "$old"; then
    echo "warning: $old still contains second-look rules from an older install." >&2
    echo "         Delete that section by hand so the rules don't load twice." >&2
  fi
}

install() {
  NEED_NEW_SHELL=0
  ensure_packages
  ensure_claude
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
  echo
  if [[ "$NEED_NEW_SHELL" == 1 ]]; then
    echo "Done. Close this Terminal and open a new one, then run: claude"
  else
    echo "Done. Run: claude"
  fi
}

uninstall() {
  for pair in "${FILES[@]}"; do
    target="$CLAUDE_DIR/${pair#*:}"
    if [[ -f "$target" ]]; then
      rm "$target"
      echo "removed  $target"
    fi
  done
  rmdir "$CLAUDE_DIR/second-look" 2>/dev/null || true
  warn_legacy
}

case "${1:-}" in
  "") install ;;
  --uninstall) uninstall ;;
  *) echo "usage: ./install.sh [--uninstall]" >&2; exit 2 ;;
esac

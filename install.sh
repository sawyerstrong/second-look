#!/usr/bin/env bash
# Install or sync second-look into your global Claude Code config.
#
#   ./install.sh              install, or update an existing install
#   ./install.sh --uninstall  remove it
#
# Safe to re-run. The rules live between marker lines in ~/.claude/CLAUDE.md;
# anything else in that file is left alone. Files are backed up to *.bak
# before they are changed.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
AGENTS_DIR="$CLAUDE_DIR/agents"
RULES_FILE="$CLAUDE_DIR/CLAUDE.md"
AGENTS=(reviewer.md devils-advocate.md)
START_MARK="<!-- second-look:start -->"
END_MARK="<!-- second-look:end -->"
LEGACY_HEADING="# Analysis rules (second-look)"

has_markers() {
  [[ -f "$RULES_FILE" ]] && grep -qF "$START_MARK" "$RULES_FILE" && grep -qF "$END_MARK" "$RULES_FILE"
}

check_legacy() {
  if [[ -f "$RULES_FILE" ]] && ! has_markers && grep -qF "$LEGACY_HEADING" "$RULES_FILE"; then
    echo "error: $RULES_FILE contains second-look rules from an older manual install." >&2
    echo "Delete the '$LEGACY_HEADING' section from that file by hand, then re-run this script." >&2
    exit 1
  fi
}

backup() {
  if [[ -f "$1" ]]; then
    cp "$1" "$1.bak"
  fi
}

# Print the rules file with the marked block removed.
strip_block() {
  awk -v s="$START_MARK" -v e="$END_MARK" '
    $0 == s { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip
  ' "$RULES_FILE"
}

install() {
  check_legacy
  mkdir -p "$AGENTS_DIR"

  for agent in "${AGENTS[@]}"; do
    target="$AGENTS_DIR/$agent"
    if [[ -f "$target" ]] && ! cmp -s "$REPO_DIR/.claude/agents/$agent" "$target"; then
      backup "$target"
      echo "updated  $target (old copy at $agent.bak)"
    elif [[ -f "$target" ]]; then
      echo "current  $target"
    else
      echo "added    $target"
    fi
    cp "$REPO_DIR/.claude/agents/$agent" "$target"
  done

  block="$(printf '%s\n' "$START_MARK"; cat "$REPO_DIR/CLAUDE.md"; printf '%s\n' "$END_MARK")"

  if has_markers; then
    current="$(awk -v s="$START_MARK" -v e="$END_MARK" '
      $0 == s { keep = 1 }
      keep { print }
      $0 == e { keep = 0 }
    ' "$RULES_FILE")"
    if [[ "$current" == "$block" ]]; then
      echo "current  $RULES_FILE"
      return
    fi
    backup "$RULES_FILE"
    blockfile="$(mktemp)"
    printf '%s\n' "$block" > "$blockfile"
    awk -v s="$START_MARK" -v e="$END_MARK" -v blockfile="$blockfile" '
      $0 == s { while ((getline line < blockfile) > 0) print line; skip = 1; next }
      $0 == e { skip = 0; next }
      !skip
    ' "$RULES_FILE.bak" > "$RULES_FILE"
    rm "$blockfile"
    echo "updated  $RULES_FILE (old copy at CLAUDE.md.bak)"
  elif [[ -s "$RULES_FILE" ]]; then
    backup "$RULES_FILE"
    printf '\n%s\n' "$block" >> "$RULES_FILE"
    echo "appended $RULES_FILE (your existing rules are kept; old copy at CLAUDE.md.bak)"
  else
    printf '%s\n' "$block" > "$RULES_FILE"
    echo "added    $RULES_FILE"
  fi
}

uninstall() {
  check_legacy
  for agent in "${AGENTS[@]}"; do
    if [[ -f "$AGENTS_DIR/$agent" ]]; then
      rm "$AGENTS_DIR/$agent"
      echo "removed  $AGENTS_DIR/$agent"
    fi
  done
  if has_markers; then
    backup "$RULES_FILE"
    strip_block > "$RULES_FILE.tmp"
    mv "$RULES_FILE.tmp" "$RULES_FILE"
    echo "removed  second-look rules from $RULES_FILE (old copy at CLAUDE.md.bak)"
  fi
}

case "${1:-}" in
  "") install ;;
  --uninstall) uninstall ;;
  *) echo "usage: ./install.sh [--uninstall]" >&2; exit 2 ;;
esac

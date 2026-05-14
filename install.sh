#!/usr/bin/env bash
# Symlink skills/* and commands/*.md into ~/.claude/.
# Idempotent. Refuses to overwrite anything that isn't already our symlink.
# Usage: ./install.sh [--dry-run]

set -euo pipefail

DRY_RUN=0
case "${1:-}" in
  --dry-run) DRY_RUN=1 ;;
  "")        ;;
  *)         echo "usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
SKILLS_DEST="${CLAUDE_DIR}/skills"
COMMANDS_DEST="${CLAUDE_DIR}/commands"

errors=0

run() {
  if (( DRY_RUN )); then
    printf 'DRY-RUN: %s\n' "$*"
  else
    "$@"
  fi
}

link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      printf 'ok    %s -> %s\n' "$dst" "$src"
      return 0
    fi
    printf 'ERROR %s is a symlink to %s (expected %s)\n' "$dst" "$current" "$src" >&2
    errors=$((errors + 1))
    return 1
  fi
  if [[ -e "$dst" ]]; then
    printf 'ERROR %s exists and is not a symlink; not touching it\n' "$dst" >&2
    errors=$((errors + 1))
    return 1
  fi
  run ln -s "$src" "$dst"
  printf 'link  %s -> %s\n' "$dst" "$src"
}

run mkdir -p "$SKILLS_DEST" "$COMMANDS_DEST"

shopt -s nullglob

for dir in "$REPO_ROOT/skills"/*/; do
  name="$(basename "$dir")"
  link "${dir%/}" "$SKILLS_DEST/$name" || true
done

for file in "$REPO_ROOT/commands"/*.md; do
  name="$(basename "$file")"
  link "$file" "$COMMANDS_DEST/$name" || true
done

if (( errors > 0 )); then
  printf '\n%d error(s). Resolve the conflicts above and re-run.\n' "$errors" >&2
  exit 1
fi

printf '\ndone.\n'

#!/usr/bin/env bash
# Symlink skills/* and commands/*.md into ~/.claude/.
# Everything installed from this repo gets $SUFFIX appended to its name, so
# /trim-comments here becomes /trim-comments-mine when invoked.
# Idempotent. Refuses to overwrite anything that isn't already our symlink.
# Usage: ./install.sh [--dry-run]

set -euo pipefail

# Appended to every installed skill/command name. Repo filenames stay clean;
# the suffix is applied here, at link time. Changing it re-links everything and
# prunes the old names on the next run.
SUFFIX="-mine"

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

# Built-in Claude Code slash commands. Custom commands with these names are
# unreachable (the built-in always wins), so refuse to link them.
# Keep in sync with the "Command naming" section of CLAUDE.md.
BUILTIN_COMMANDS=(
  help clear compact config cost model init review agents skills
  memory permissions status bug feedback login logout exit quit
  release-notes upgrade mcp hooks doctor ide pr-comments resume
  vim terminal-setup add-dir migrate-installer
)

is_builtin() {
  local name="$1"
  local b
  for b in "${BUILTIN_COMMANDS[@]}"; do
    [[ "$name" == "$b" ]] && return 0
  done
  return 1
}

errors=0

# Destination paths this run intends to own. Anything else in ~/.claude that
# points back into this repo is stale (renamed, deleted, or suffix changed) and
# gets pruned at the end.
declare -A EXPECTED=()

run() {
  if (( DRY_RUN )); then
    printf 'DRY-RUN: %s\n' "$*"
  else
    "$@"
  fi
}

link() {
  local src="$1" dst="$2"
  EXPECTED["$dst"]=1
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
  link "${dir%/}" "$SKILLS_DEST/${name}${SUFFIX}" || true
done

for file in "$REPO_ROOT/commands"/*.md; do
  stem="$(basename "$file" .md)"
  installed="${stem}${SUFFIX}"
  # With a non-empty SUFFIX a collision is impossible, but the check stays
  # correct if SUFFIX is ever cleared.
  if is_builtin "$installed"; then
    printf 'ERROR /%s collides with a built-in slash command; refusing to link %s. Rename or prefix it.\n' "$installed" "$file" >&2
    errors=$((errors + 1))
    continue
  fi
  link "$file" "$COMMANDS_DEST/${installed}.md" || true
done

# Remove symlinks in ~/.claude that point into this repo but are no longer
# expected — leftovers from a rename, a deleted file, or an old SUFFIX. Links
# pointing anywhere else are none of our business and are left alone.
for dest_dir in "$SKILLS_DEST" "$COMMANDS_DEST"; do
  for entry in "$dest_dir"/*; do
    [[ -L "$entry" ]] || continue
    [[ "$(readlink "$entry")" == "$REPO_ROOT/"* ]] || continue
    [[ -n "${EXPECTED["$entry"]:-}" ]] && continue
    run rm "$entry"
    printf 'prune %s (stale link into this repo)\n' "$entry"
  done
done

if (( errors > 0 )); then
  printf '\n%d error(s). Resolve the conflicts above and re-run.\n' "$errors" >&2
  exit 1
fi

printf '\ndone.\n'

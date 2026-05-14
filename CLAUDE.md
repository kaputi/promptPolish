# promptPolish

Personal authoring workspace for Claude Code skills, slash commands, and paste-in prompts. Edits here surface to Claude Code via symlinks into `~/.claude/`.

## Layout

```
skills/<name>/SKILL.md   → symlinked to ~/.claude/skills/<name>/
commands/<name>.md       → symlinked to ~/.claude/commands/<name>.md
prompts/<name>.md        → NOT symlinked; copy/paste into a Claude Code message
```

## Install

`./install.sh` symlinks every skill and command into `~/.claude/`. It is idempotent and refuses to overwrite anything it didn't create.

- `./install.sh` — apply
- `./install.sh --dry-run` — preview

Edits to already-symlinked files take effect immediately. Only re-run `install.sh` after **adding** a new skill or command.

## Conventions

- **Names** are kebab-case (`my-skill/`, `polish-prompt.md`).
- **Skills** live as a directory under `skills/` containing `SKILL.md` with YAML frontmatter (`name`, `description`). The `description` field is the trigger — write it so future-Claude can decide whether the skill applies. Use the `superpowers:writing-skills` skill before authoring.
- **Slash commands** are single `.md` files under `commands/`. Filename (minus `.md`) becomes the slash command name.
- **Paste-in prompts** are plain markdown under `prompts/`. No frontmatter. Not installed anywhere — they're meant to be copied into a chat manually.

## Operating notes for Claude

- Before authoring a new skill, invoke `superpowers:writing-skills`. It covers frontmatter, progressive disclosure, and verification — do not freelance the structure.
- One skill = one trigger. If a description starts listing unrelated capabilities, split it.
- Keep `SKILL.md` content lean. Push examples, scripts, and long references into sibling files inside the skill folder.
- Don't touch `~/.claude/` directly to install something authored here — always go through `install.sh` so the symlink is the source of truth.
- Git is managed by the user. Recommend commands; don't run them.

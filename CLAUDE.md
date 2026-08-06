# promptPolish

Personal authoring workspace for Claude Code skills, slash commands, and paste-in prompts. Edits here surface to Claude Code via symlinks into `~/.claude/`.

## Layout

```
skills/<name>/SKILL.md   → symlinked to ~/.claude/skills/<name>-mine/
commands/<name>.md       → symlinked to ~/.claude/commands/<name>-mine.md
prompts/<name>.md        → NOT symlinked; copy/paste into a Claude Code message
```

Everything installed from this repo gets the **`-mine` suffix** appended at link
time. Repo filenames stay clean; `commands/trim-comments.md` is invoked as
`/trim-comments-mine`. The suffix lives in the `SUFFIX` variable at the top of
`install.sh` — change it there and the next run re-links everything and prunes
the old names.

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

## Command naming — avoid built-in collisions

Custom slash commands **cannot shadow** Claude Code built-ins. Typing `/config` always triggers the built-in UI even if `commands/config.md` exists, so the file would be unreachable. Avoid these names:

`help`, `clear`, `compact`, `config`, `cost`, `model`, `init`, `review`, `agents`, `skills`, `memory`, `permissions`, `status`, `bug`, `feedback`, `login`, `logout`, `exit`, `quit`, `release-notes`, `upgrade`, `mcp`, `hooks`, `doctor`, `ide`, `pr-comments`, `resume`, `vim`, `terminal-setup`, `add-dir`, `migrate-installer`

For domain-adjacent names, prefix instead — `pp-config`, `my-review`, etc. Run `/help` in any session to see the current built-in set.

`install.sh` refuses to link a command whose name is in this list. If Claude Code ships a new built-in, update the `BUILTIN_COMMANDS` array at the top of `install.sh` *and* the list above.

In practice the `-mine` suffix already makes a built-in collision impossible — no built-in ends in `-mine`. The check is kept because it stays correct if `SUFFIX` is ever cleared, and it's checked against the *installed* name, not the repo filename.

**Precedence, for context:** commands and skills resolve enterprise → personal (`~/.claude`) → project (`.claude`) → bundled. Personal wins over project, the opposite of `settings.json`. Since this repo installs into `~/.claude`, every name it claims is claimed globally for the user — a per-project `.claude/commands/<same-name>.md` would be shadowed and unreachable. The suffix keeps that footprint clearly namespaced.

## Operating notes for Claude

- Before authoring a new skill, invoke `superpowers:writing-skills`. It covers frontmatter, progressive disclosure, and verification — do not freelance the structure.
- One skill = one trigger. If a description starts listing unrelated capabilities, split it.
- Keep `SKILL.md` content lean. Push examples, scripts, and long references into sibling files inside the skill folder.
- Don't touch `~/.claude/` directly to install something authored here — always go through `install.sh` so the symlink is the source of truth.
- Git is managed by the user. Recommend commands; don't run them.

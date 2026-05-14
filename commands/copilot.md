---
description: Implement a plan with Claude driving — every meaningful step is confirmed with the user first
argument-hint: <path-to-plan.md>
---

You are entering **copilot mode**. You are the pilot for the rest of this conversation; the user is the copilot.

Plan path: `$ARGUMENTS`

## What this means

- **You drive.** You choose the next step based on the plan, but you do not execute meaningful steps without confirming first.
- **Per-step protocol:**
  1. State concisely: what you intend to do, why, and which files/tests it will touch.
  2. Wait for confirmation, adjustment, or redirection.
  3. Only then act.
- **"Step" granularity.** A step is a discrete unit of work: a file edit, a test run, a refactor, an investigation. A single obvious follow-up edit that continues a just-confirmed step does not need a fresh stop. A new file, a new direction, or anything the user might want to redirect — does.
- **You still verify.** Copilot mode does not skip applicable skills (`superpowers:test-driven-development`, `superpowers:systematic-debugging`, `superpowers:verification-before-completion`). Invoke them when relevant.

## Decisions file

Maintain a journal at `<plan-dir>/<plan-stem>-decisions.md`, derived from the plan path:

- `docs/plans/foo-plan.md` → `docs/plans/foo-decisions.md` (strip trailing `-plan`, append `-decisions.md`)
- `docs/plans/foo.md` → `docs/plans/foo-decisions.md` (no `-plan` suffix, insert `-decisions` before `.md`)

### Bootstrapping

- If the file doesn't exist: create with `# Decisions — <plan-name>` followed by a markdown link to the plan.
- If it exists: append a `## Session resumed — <YYYY-MM-DD HH:MM>` entry with a one-line summary of where work left off, inferred from the last entries.

### What to log

Append an entry when any of these happen:

- **Choice between alternatives.** Record what was picked and *why*. If the user overrode your proposal, capture that — their reasoning is the signal.
- **Debugging finding.** Failed test or unexpected behavior, root cause, what fixed it.
- **Deviation from the plan.** Plan said X, we did Y, because.
- **Backtrack.** Start the entry with `Returned to <step>` and note what was abandoned and why.

### What NOT to log

- Routine successful edits — the diff and git history are the record.
- Each confirmation in isolation. Log only when the confirmation reshaped the direction.
- Conversational back-and-forth.
- Speculation that didn't lead to a decision.

### Entry format

Plain markdown. One `## H2` per entry: `## <YYYY-MM-DD HH:MM> — <short title>`. Body is 1–10 lines.

**Append-only.** Never edit or delete prior entries. If you reverse direction, the prior entry stays and a new "Returned to…" entry is appended on top.

## Startup sequence

1. Read the plan at `$ARGUMENTS`. If the path is missing or unreadable, say so and stop.
2. Read the decisions file if it exists. Summarize for the user: where work currently stands, what was decided previously, what's still open.
3. Propose the next step per the protocol above. Wait for confirmation.

Stay in copilot mode for the rest of this conversation. To switch, the user will invoke `/pilot`.

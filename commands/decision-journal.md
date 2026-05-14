---
description: Start or resume a decisions journal for the current context — debugging, implementation, refactor, anything
---

You are starting a **decisions journal** for the rest of this conversation. This is not a mode change — keep doing whatever work is currently happening. The only new behavior is maintaining the journal alongside that work.

## Startup flow

Run these steps interactively, one at a time. Wait for the user's answer before continuing.

### 1. Ask: load existing or create new?

> "Load an existing decisions journal, or create a new one?"

### 2a. Load existing

- Ask the user for the path (relative to CWD or absolute).
- Verify the file exists and is readable. If it doesn't exist, tell the user and fall through to **Create new** (step 2b).
- Read the file. Summarize for the user: title, number of entries, what the last few entries cover.
- Append a new entry:
  ```
  ## <YYYY-MM-DD HH:MM> — Session resumed
  <one-line summary of where prior work left off and what the current conversation is about>
  ```

### 2b. Create new

- Propose a default title using today's date: `Decisions — <YYYY-MM-DD>`.
- Ask the user whether to use the default or provide a custom suffix. The `Decisions — ` prefix is **mandatory** — only the part after `— ` is user-defined.
  - Default example: `Decisions — 2026-05-14`
  - Custom example: `Decisions — Auth bug investigation`
- Validate the suffix:
  - Reject if the user's suffix contains a path separator (`/` or `\`) or starts with `.` — re-ask with a brief explanation that the suffix is a title, not a path.
- Derive the filename from the suffix: lowercase, replace runs of non-alphanumerics with `-`, strip leading/trailing `-`, then prepend `decisions-` and append `.md`. Place it in CWD.
  - `Decisions — 2026-05-14` → `decisions-2026-05-14.md`
  - `Decisions — Auth bug investigation` → `decisions-auth-bug-investigation.md`
- Show the user the derived filename and ask for a Y/n confirmation before creating. If they reject, re-ask for a different suffix.
- If a file at that path already exists, stop and surface the conflict — ask whether to load it instead, choose a different suffix, or abort.
- Create the file with this initial content:
  ```
  # <title chosen by user>

  ## <YYYY-MM-DD HH:MM> — Context at journal start
  <1–3 line summary of what is going on in the conversation right now: debugging X, implementing Y, refactoring Z, etc.>
  ```

## Logging rules (active from here on)

Append an entry to the journal when any of these happen:

- **Choice between alternatives.** Record what was picked and *why*. If the user overrode a proposal, capture that — their reasoning is the signal.
- **Debugging finding.** Failed test or unexpected behavior, root cause, what fixed it.
- **Deviation from the original direction.** "We were going to do X, switched to Y because…"
- **Backtrack.** Start the entry with `Returned to <state>` and note what was abandoned and why.

### What NOT to log

- Routine successful edits — the diff and git history are the record.
- Conversational back-and-forth.
- Speculation that didn't lead to a decision.

### Entry format

Plain markdown. One `## H2` per entry: `## <YYYY-MM-DD HH:MM> — <short title>`. Body is 1–10 lines.

**Append-only.** Never edit or delete prior entries. If direction reverses, the prior entry stays and a new `Returned to…` entry is appended on top.

## Persistence

The journal stays active for the rest of this conversation. There is no exit command — the next `/decision-journal` invocation in a future session can resume it via the **Load existing** path.

---
description: Review comments added on this branch one by one and trim the redundant ones
argument-hint: [target-branch]
---

You are entering **trim-comments mode**. The goal is to find comments this branch
added and cut the noise. AI-written code tends to over-comment: if the variable
name, the function name, or the code itself already says it, the comment is
dead weight. Your bias is toward *less*.

Target branch: `$ARGUMENTS` (default `develop`)

## Phase 1 — Discovery

Resolve the target branch first: try `$ARGUMENTS` (or `develop` if empty), then
`origin/<name>`. If neither resolves, stop and print `git branch -a` output so
the user can pick.

Then:

```
git diff --merge-base <target> HEAD -U5
```

Merge-base so commits landed on the target since you branched don't pollute the
list. `-U5` so a pre-existing comment sitting above an added function is visible.

**What counts as in scope:**

- Comment lines added in the diff (`+` lines that are comments).
- Comments in the surrounding context that document a changed code block — e.g.
  an untouched comment directly above a function whose body you rewrote.

**What doesn't:**

- Files that are only deleted, lockfiles, generated output, vendored code, `.md`
  and other prose files. Source files only.

**For each comment, record:**

- File path and the line the comment *starts* on.
- The full comment text.
- The symbol it documents — the next non-blank declaration below it (function,
  method, class, variable, type), or the enclosing function if it sits mid-body.

A multi-line comment is **one entry**. A `/** … */` block, a run of consecutive
`//` lines, and a docstring each count as a single item — never one entry per
line.

If there are no added comments, say so and stop.

## Phase 2 — The list

Print the full list before touching anything. Group by file, number globally:

```
Found 17 added comments across 6 files.

### [3] src/api/user.ts:42 — fetchUserProfile()
// Fetch the user profile from the API and return it as a
// UserProfile object. Throws if the request fails.
```

Then ask whether to enter review mode.

If there are more than ~25 entries, offer first to either batch the prompts or
triage the worst offenders before going one by one.

## Phase 3 — Review mode

One comment per message. Never bundle two comments into one prompt unless the
user asked for batching.

```
[3/17] src/api/user.ts:42 — fetchUserProfile()

// Fetch the user profile from the API and return it as a
// UserProfile object. Throws if the request fails.

  1. Remove entirely  (recommended)
  2. Keep as-is
  3. Shorten → // Throws on non-2xx.

Recommended (1): the name and return type already say "fetch user profile";
the throw is visible two lines down.

1/2/3, or `no` to skip · free text works too
```

The option *set* varies per comment. "Keep as-is" is always present; add
whichever of remove / shorten / rewrite genuinely apply. Do not pad to a fixed
count, and do not invent a third option to fill the slot. Always state which
option you recommend and why, in one or two sentences.

Free-text answers ("shorter", "drop the second sentence", "keep but fix the
typo") are valid — adapt and apply.

### Judgment rules

**Remove** when the comment:

- restates the function, method, or variable name
- restates the signature or return type
- narrates the line below it (`// loop over users`, `// increment counter`)
- states something obvious from the code
- is AI scaffolding: `// Step 1:`, `// Helper function`, `// Main logic`,
  section banners inside a short function

**Shorten** when there is one real fact buried in three sentences of prose.
Keep the fact, drop the rest.

**Rewrite** when the comment explains *what* the code does but the valuable
content is *why* — and the why is actually inferable from the diff.

**Keep** when the comment:

- explains why rather than what
- warns about a non-obvious constraint, ordering requirement, or workaround
- references an issue, ticket, spec, or upstream bug
- documents a public API contract (weigh this before recommending removal of a
  docstring — on an exported symbol a docstring can be load-bearing for IDE
  hovers and generated docs even when it restates the signature)
- encodes domain knowledge that isn't recoverable from the code

**Never fabricate a rationale.** If the "why" behind a comment isn't knowable
from the code in front of you, do not invent one to justify a rewrite. Say the
intent is unclear and recommend keep-or-shorten instead.

## Phase 4 — Apply

Apply the chosen edit **immediately**, before moving to the next comment.

- Match the edit on the comment's *text*, not its line number. Line numbers
  drift; text doesn't.
- After each applied edit, compute its net line delta and add that offset to
  every remaining entry in the same file, so later prompts show correct line
  numbers. This is arithmetic on the list you already built — do not re-run the
  diff or re-read the file for it.
- If a file turns out to have changed since Phase 1 and the text match fails,
  re-read that file before editing.

Track outcomes as you go.

## Wrap-up — change report

When the last comment has been handled (or the user stops early), print a report
of what actually changed. Two parts.

**Tally**, one line:

```
17 reviewed · 8 removed · 4 shortened · 1 rewritten · 3 kept · 1 skipped
```

**Detail**, one block per comment that was *modified* — skip the kept and
skipped ones, they didn't change:

```
### src/api/user.ts:42 — fetchUserProfile()  [removed]
- // Fetch the user profile from the API and return it as a
- // UserProfile object. Throws if the request fails.

### src/db/pool.ts:88 — acquireConnection()  [shortened]
- // Acquire a connection from the pool. This will block until one is
- // available or the timeout is reached, at which point it throws.
+ // Blocks until a connection frees up; throws at timeout.
```

Line numbers in the report are the **original** Phase 1 numbers, so they match
the list the user reviewed against. Note the net line count removed across the
branch, then suggest `git diff` to see it in place.

If the report runs long (more than ~15 modified comments), offer to write it to
a file rather than filling the terminal — default `comment-trim-report.md` in
the repo root, and mention it's untracked.

Do not commit. Git is the user's.

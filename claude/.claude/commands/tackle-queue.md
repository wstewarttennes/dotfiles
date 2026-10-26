---
description: Work through Weston's daily queue — pull the goblin master inbox (high priority first), map every task to Linear, categorize, check off items owned by others (or already shipped), then tackle Code Review tickets with /code-review.
---

# /tackle-queue

Master command that runs Weston's whole task queue end-to-end. Reconciles the goblin
master inbox against Linear, cleans up what isn't his to do, and drives the active work. Designed to grow — add new stages at the end as we expand it.

## Identity / constants
- **Weston in Linear**: name `Weston Stewart-Tennes`, id `f797dd2c-4ea6-4819-87c3-035343c079d0`, displayName `weston`.
- **Primary Linear team**: `Development` (key `CF`, City Flavor). Goblin project → team `Goblin`.
- **CityFlavor repo** (for PRs / code review): `cityflavor/ftf`.
- MCP servers used: `goblin-prod`, `linear`. If Linear shows only `authenticate`/`needs auth`,
  run `mcp__linear__authenticate` first.

## Stage 1 — Pull the open queue from the goblin master inbox
Weston's work queue lives in goblin's master inbox (Linear, Gmail, Slack and manual items).
1. `mcp__goblin-prod__get_inbox_items` with `status: open`, following `next_offset` until it is null
   (never trust page 1).
2. Dump the items (`id, title, source, priority, url, planned_date`) to a scratchpad JSON file,
   grouped by priority (high / medium / low / none). Report the per-priority counts up front.

## Stage 2 — Map every task to Linear + categorize
For each inbox item, find its Linear issue and record `status`, `status_type`, `assignee`:
- If the title/links contain a `CF-####` id or a `linear.app/.../issue/CF-####` URL → `mcp__linear__get_issue`.
- Else search `mcp__linear__list_issues` with `query` = a distinctive title substring, `team: Development`
  (or `Goblin`). Error-tracker titles (OperationalError/AttributeError/IntegrityError/NameError/
  "Failed to save automation run"/etc.) usually exist as Linear issues — search the distinctive part.
- Slack/email pastes, notifications, and personal tasks usually have **no** Linear ticket → mark match none; leave them alone.
- **Fan this out to ~4 parallel subagents** (general-purpose) over slices of the inbox items; each returns
  a compact JSON array `{index, inbox_id, title, linear_id, linear_status, status_type, assignee, assigned_to_weston, match_confidence}`. Keep the big Linear payloads out of the main context.
- Be conservative: only act on high/med-confidence matches.

Produce a **categorization**: group matched tickets by Linear status
(Triage / Backlog / Todo / In Progress / Code Review / QA / QA Complete / Merged / Done / Canceled),
and separately list the non-Linear items.

## Stage 3 — Clear from the inbox what isn't Weston's active work
For every item that is a confident Linear match AND either:
- **assigned to someone other than Weston** → `mcp__goblin-prod__dismiss_inbox_item` (hides it, never touches Linear), OR
- **already shipped** (status Merged or Done) → `mcp__goblin-prod__complete_inbox_item` with
  `push_to_source: false`. NEVER let it default to true here — that marks the Linear issue Done.

Also **dedupe**: when several inbox items map to the same ticket, keep one and dismiss the rest.
(To UNDO: `mcp__goblin-prod__reopen_inbox_item` with `push_to_source: false`.)

Report the exact list of what got cleared (Linear id, status, assignee) — never silently.

## Stage 4 — Tackle Code Review
For every ticket now in **Code Review** status **assigned to Weston**:
1. `mcp__linear__get_issue` to read its `attachments` and get the GitHub PR (`github.com/cityflavor/ftf/pull/NNNN`).
2. Run the review — `/code-review ultra <PR#>` (or `/review <PR#>`). Use `--comment` to post inline PR comments when asked.
3. Summarize findings per ticket.

## Stage 5 — (extend here)
Future stages go here — e.g. auto-advance QA-Complete tickets, draft replies to Slack-thread tasks,
triage the non-Linear personal items, run tests on In-Progress tickets, etc.

## Output
End with: the categorized breakdown by Linear status, the list of items checked off (with why),
the Code Review results, and what remains as Weston's active queue.

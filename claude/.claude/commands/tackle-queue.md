---
description: Work through Weston's daily queue — pull the Akiflow "High Priority" slot, map every task to Linear, categorize, check off items owned by others (or already shipped), then tackle Code Review tickets with /code-review.
---

# /tackle-queue

Master command that runs Weston's whole task queue end-to-end. Reconciles the Akiflow
"High Priority" time-slot against Linear, cleans up what isn't his to do, and drives the
active work. Designed to grow — add new stages at the end as we expand it.

## Identity / constants
- **Weston in Linear**: name `Weston Stewart-Tennes`, id `f797dd2c-4ea6-4819-87c3-035343c079d0`, displayName `weston`.
- **Primary Linear team**: `Development` (key `CF`, City Flavor). Goblin project → team `Goblin`.
- **CityFlavor repo** (for PRs / code review): `cityflavor/ftf`.
- MCP servers used: `akiflow`, `linear`. If either shows only `authenticate`/`needs auth`,
  run its OAuth flow first (Akiflow: `mcp__akiflow__authenticate`; Linear: `mcp__linear__authenticate`).

## Stage 1 — Pull today's "High Priority" slot from Akiflow
1. `mcp__akiflow__get_schedule` for **today only**, `entities: tasks`, `completed_mode: with_completed`.
   (Output is large — it saves to a file; use `jq` on that file, don't read it raw.)
2. The "High Priority" time slot **moves day to day** — do NOT hardcode a time. Find it by
   grouping OPEN tasks by time-of-day and taking the datetime cluster with the most open tasks:
   `jq -r '[.tasks[]|select((.done|not) and .datetime!=null)] | group_by(.datetime|sub(".*T";""))[] | "\(.[0].datetime|sub(".*T";"")): \(length)"' FILE | sort -t: -k2 -rn | head`
3. Dump that slot's OPEN tasks (`akiflow_id, title, project, priority, links`) to a scratchpad JSON file.

## Stage 2 — Map every task to Linear + categorize
For each slot task, find its Linear issue and record `status`, `status_type`, `assignee`:
- If the title/links contain a `CF-####` id or a `linear.app/.../issue/CF-####` URL → `mcp__linear__get_issue`.
- Else search `mcp__linear__list_issues` with `query` = a distinctive title substring, `team: Development`
  (or `Goblin`). Error-tracker titles (OperationalError/AttributeError/IntegrityError/NameError/
  "Failed to save automation run"/etc.) usually exist as Linear issues — search the distinctive part.
- Slack/email pastes, notifications, and personal tasks usually have **no** Linear ticket → mark match none; leave them alone.
- **Fan this out to ~4 parallel subagents** (general-purpose) over slices of the task list; each returns
  a compact JSON array `{index, akiflow_id, title, linear_id, linear_status, status_type, assignee, assigned_to_weston, match_confidence}`. Keep the big Linear payloads out of the main context.
- Be conservative: only act on high/med-confidence matches.

Produce a **categorization**: group matched tickets by Linear status
(Triage / Backlog / Todo / In Progress / Code Review / QA / QA Complete / Merged / Done / Canceled),
and separately list the non-Linear items.

## Stage 3 — Check off in Akiflow what isn't Weston's active work
`mcp__akiflow__complete_task` for every slot task that is a confident Linear match AND either:
- **assigned to someone other than Weston**, OR
- **already shipped**: status Merged or Done (`status_type: completed`, or status name `Merged`).

Also **dedupe**: when multiple Akiflow tasks map to the same ticket, keep one canonical task and
complete the rest. (To UNDO an accidental completion: `mcp__akiflow__plan_task` with the original
`start_datetime` clears the done state.)

Report the exact list of what got checked off (Linear id, status, assignee) — never silently.

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

---
name: scratchpad
description: "Persistent working memory for multi-iteration tasks. Use for iterate mode, long-running agents, and state that survives context resets. Triggers: 'track progress', 'working memory', 'scratchpad'. NOT for: simple notes, one-shot tasks, memory/beliefs persistence (use MEMORY.md or beliefs)."
---

# Scratchpad - Agent Working Memory

Persistent state for multi-iteration agent tasks.

## Purpose

The scratchpad is a structured file that:
1. Persists agent state between iterations
2. Signals task status to iterate hooks
3. Documents progress for debugging

## Location

Default: `.claude/scratchpad.md` (project-level)
Global: `~/.claude/scratchpad.md`

## When to Use

- TDD workflows: Track RED/GREEN/REFACTOR cycles
- Bug fixing: Document hypotheses and findings
- Multi-file refactors: Track file progress
- Any task requiring iteration to completion

## Template

```markdown
# Scratchpad

## Current Task
[One sentence objective]

## Status
`IN_PROGRESS`

## Progress
- [ ] Step 1
- [x] Step 2 (completed)
- [ ] Step 3

## Context
[Key info for next iteration]

## Blockers
None | BLOCKED: <reason>

## Notes
[Observations and decisions]
```

## Status Signals

| Signal | Meaning | Grind Hook Action |
|--------|---------|-------------------|
| `IN_PROGRESS` | Work ongoing | Continue |
| `TESTS_PASS` | All tests green | Stop, success |
| `DONE` | Task complete | Stop, success |
| `BLOCKED: <msg>` | Cannot proceed | Stop, report blocker |

## Integration with Grind Hooks

The iterate hook reads the scratchpad after each agent stop:

1. Agent completes a turn
2. Grind hook checks scratchpad
3. If `DONE` or `TESTS_PASS` → stop
4. If `BLOCKED` → stop and report
5. Otherwise → trigger next iteration

## Commands

### Initialize Scratchpad

```
/scratchpad init "Implement user authentication"
```

Creates new scratchpad with task description.

### Update Status

```
/scratchpad status TESTS_PASS
```

Updates the status signal.

### Clear Scratchpad

```
/scratchpad clear
```

Removes scratchpad after task completion.

## Best Practices

1. **Keep it concise** - Focus on actionable info
2. **Update every iteration** - Don't let it get stale
3. **Mark progress immediately** - Check boxes as you go
4. **Document blockers clearly** - Include what's needed to unblock
5. **Clear when done** - Start fresh for next task

## Example: TDD Workflow

```markdown
# Scratchpad

## Current Task
Implement validateEmail function with TDD

## Status
`IN_PROGRESS`

## Progress
- [x] Write test cases for valid emails
- [x] Write test cases for invalid emails
- [x] Run tests (RED - all failing as expected)
- [ ] Implement validateEmail
- [ ] Run tests (GREEN)
- [ ] Refactor if needed

## Context
- Tests in: src/__tests__/validateEmail.test.ts
- Implementation: src/utils/validateEmail.ts
- Pattern: RFC 5322 compliant

## Blockers
None

## Notes
- Need to handle unicode domain names
- Edge case: empty string should return false
```

## Trigger Phrases

- "use scratchpad for this task"
- "track progress in scratchpad"
- "initialize scratchpad"
- "update scratchpad status"

---
name: evidence-gate
description: "Refuse claims of completion without proof. Force the agent to identify the command that would prove the claim, run it fresh, read the actual output, and report PASS/FAIL with evidence. Companion to fpf's calibration tags — the gate that makes [OBSERVED] tags trustworthy. Triggers: '/evidence-gate', 'prove it', 'double check', 'is it really done'. NOT for: spelling checks, trivial questions, simple confirmations."
---

# Evidence Gate — Refuse Completion Without Proof

## Iron Law

**No completion claims without fresh verification evidence.** If you haven't run the command in this message, you cannot claim it passes.

## Gate (every time, no exceptions)

1. **IDENTIFY** — what command proves this claim?
2. **RUN** — execute it fresh, full output
3. **READ** — check exit code, count failures
4. **VERIFY** — does output confirm the claim?
   - NO → state actual status with evidence
   - YES → state claim WITH evidence
5. **ONLY THEN** — make the claim

## What counts as proof

| Claim | Requires | NOT sufficient |
|-------|----------|----------------|
| Tests pass | Test output: 0 failures | "should pass", previous run |
| Lint clean | Linter output: 0 errors | partial check |
| Build succeeds | Build: exit 0 | "linter passed" |
| Bug fixed | Reproduce test passes | "code changed" |
| Requirements met | Line-by-line checklist | "tests pass" |

## Red flags — STOP and verify

- Words: "should", "probably", "seems to", "looks correct"
- Celebrating before evidence: "Done!", "Perfect!", "All good!"
- About to commit/push/PR without running tests
- Trusting agent reports without checking diff
- "Just this once" / "I'm confident" / "Partial check is enough"

## Multi-angle review (for significant work)

| Angle | Ask |
|-------|-----|
| User | Does it work as expected? Edge cases? |
| Reviewer | Would a reviewer approve? Obvious issues? |
| Attacker | Security holes? Input validation? |
| Future dev | Understandable? Maintainable? |

## Verdict format

```
VERIFY: PASS/FAIL
Evidence: [command output summary]
[If FAIL]: Issues: 1. ... 2. ...
```

## Why this exists

Claiming done without proof is dishonesty, not efficiency. Evidence before assertions, always.

---
name: tribunal
description: "Provider-relative independent audit. The current agent arbitrates while the two other external AI CLIs review in parallel: Claude+Gemini for Codex, Codex+Gemini for Claude, Claude+Codex for Gemini. Use for security-sensitive code, critical bug fixes, pre-production deploys. Triggers: /tribunal, 'dual audit', 'independent review'."
---

# Tribunal

Independent multi-model audit. The current agent is the arbiter; the auditors are the two other providers, selected from Claude, Codex, and Gemini.

The point is independence. Never use the current runtime as one of its own auditors.

## Prerequisites

Local CLIs for the two providers you do **not** currently run as the host:

| Provider | CLI binary | Auth check |
|----------|-----------|------------|
| Claude | `claude` | `claude --version` |
| Codex | `codex` | `codex --version` |
| Gemini | `gemini` | `gemini --version` |

Each CLI must already be logged in / configured. Tribunal does **not** start interactive auth flows.

## Protocol

### 1. Input Modes

```bash
# File review
/tribunal path/to/file.py

# Uncommitted changes
/tribunal

# Critical mode (stronger/slower models)
/tribunal --critical
```

### 2. Select Auditors

Detect the current runtime first, then run the other two providers.

| Current runtime | Auditor 1 | Auditor 2 | Arbiter |
|-----------------|-----------|-----------|---------|
| Claude Code | Codex | Gemini | Current Claude agent |
| Codex | Claude | Gemini | Current Codex agent |
| Gemini | Claude | Codex | Current Gemini agent |

If the current runtime is unclear, infer it from the host/session. If still unclear, state the uncertainty and choose two auditors that do not include the agent currently answering the user.

**Do not substitute the current agent** when an external auditor is unavailable. Report the auth/tooling blocker instead, because using yourself as an auditor breaks the tribunal guarantee.

### 3. Auth Preflight

Before claiming that a tribunal was launched, verify that both selected CLIs are available and can run non-interactively.

```bash
which claude codex gemini
claude --version
codex --version
gemini --version
```

If a CLI is missing, asks for login, opens OAuth, or hangs on permissions, stop and report the exact blocker. Do not silently downgrade or substitute the current runtime.

If you need a smoke prompt for the selected auditors:

```bash
claude -p --model sonnet --permission-mode plan --tools "" -- "Reply OK"

codex exec \
  -c model_reasoning_effort="low" \
  --sandbox read-only \
  --full-auto \
  --skip-git-repo-check \
  "Reply OK"

gemini -p "Reply OK" -m gemini-3-flash-preview -e none -o text
```

### 4. Prepare Audit Input

For file mode, prepend the file content to `AUDIT_PROMPT`.

For diff mode, prepend `git diff` output to `AUDIT_PROMPT`.

Each auditor receives the same review prompt and the same code/diff content. The current arbiter must not add its own opinion to the auditor prompts.

### 5. Audit Prompt Structure

Each auditor receives an identical prompt. Do not mention the other auditor.

```text
You are conducting an independent code audit. Review the following code for:

- Security vulnerabilities (injection, auth bypass, data leaks, insecure crypto)
- Correctness (logic errors, edge cases, off-by-one, null handling)
- Performance issues (N+1 queries, inefficient algorithms, memory leaks)
- Maintainability (complexity, coupling, unclear contracts, technical debt)

Provide structured output:

VERDICT: [APPROVE | CONCERNS | REJECT]
SEVERITY: [CRITICAL | HIGH | MEDIUM | LOW | NONE]

FINDINGS:
[List specific issues with file:line references]

REASONING:
[Explain your assessment: why this verdict, what patterns led to it]

Be specific. Reference exact lines. Distinguish between critical flaws and minor improvements.

CODE TO REVIEW:
[content piped via stdin or included in prompt]
```

### 6. Launch Auditors

Run the selected two auditors in parallel when the host agent supports parallel tool calls. Each auditor must return an independent output. If the tool surface captures stdout directly, store that captured text as the auditor output; temp files are optional. Otherwise redirect to `/tmp/tribunal-*.txt`.

#### Claude Auditor

Standard mode:

```bash
claude -p \
  --model sonnet \
  --permission-mode plan \
  --tools "" \
  --no-session-persistence \
  -- "AUDIT_PROMPT"
```

Critical mode:

```bash
claude -p \
  --model opus \
  --effort high \
  --permission-mode plan \
  --tools "" \
  --no-session-persistence \
  -- "AUDIT_PROMPT"
```

If Opus is not available for the account, use `--model sonnet --effort high` and disclose the downgrade in the final synthesis.

#### Codex Auditor

Standard mode:

```bash
codex exec \
  -c model_reasoning_effort="high" \
  --sandbox read-only \
  --full-auto \
  --skip-git-repo-check \
  "AUDIT_PROMPT"
```

Critical mode:

```bash
codex exec \
  -c model_reasoning_effort="xhigh" \
  --sandbox read-only \
  --full-auto \
  --skip-git-repo-check \
  "AUDIT_PROMPT"
```

Codex quirks:

- Do not use `-m` unless the local Codex account is known to support that model.
- Do not use `-o` for `codex exec` audit output; capture stdout from the agent tool call.

#### Gemini Auditor

Standard mode:

```bash
gemini -p "AUDIT_PROMPT" \
  -m gemini-3-flash-preview \
  -e none \
  -o text
```

Critical mode:

```bash
gemini -p "AUDIT_PROMPT" \
  -m gemini-3.1-pro-preview \
  -e none \
  -o text
```

Gemini quirks:

- Use `-e none` for headless runs to avoid extension startup overhead.
- Use `-o text` for human-readable output.
- If Gemini attempts browser OAuth during a tribunal run, stop and report auth is missing.

### 7. Capture and Read

Examples for temp-file mode (one file per auditor):

```bash
claude -p --model sonnet --permission-mode plan --tools "" --no-session-persistence -- "AUDIT_PROMPT" > /tmp/tribunal-claude.txt 2>/dev/null
codex exec -c model_reasoning_effort="high" --sandbox read-only --full-auto --skip-git-repo-check "AUDIT_PROMPT" > /tmp/tribunal-codex.txt 2>/dev/null
gemini -p "AUDIT_PROMPT" -m gemini-3-flash-preview -e none -o text > /tmp/tribunal-gemini.txt 2>/dev/null
```

Then read only the two relevant files:

```bash
cat /tmp/tribunal-claude.txt
cat /tmp/tribunal-gemini.txt
```

### 8. Arbiter Synthesis

After both selected auditors complete, read only their outputs.

Decision matrix:

| Auditor A | Auditor B | Arbiter Action |
|-----------|-----------|----------------|
| APPROVE | APPROVE | PASS: both agree, low risk |
| REJECT | REJECT | FAIL: both found critical issues |
| APPROVE | CONCERNS | Analyze concerns, decide if blocking |
| CONCERNS | REJECT | Likely fail; investigate if the other auditor missed a critical issue |
| REJECT | APPROVE | Investigate; one auditor may be too strict or may have caught a real blocker |
| CONCERNS | CONCERNS | Compare severity and decide threshold |

Synthesis rules:

1. If both approve, pass unless the arbiter independently sees an obvious blocker in the cited code.
2. If both reject, fail unless both findings are factually wrong after checking line references.
3. If they disagree, compare specific findings, line references, and severity claims.
4. The arbiter may add its own verified findings, but must label them separately from external auditor findings.

Output format:

```text
TRIBUNAL VERDICT

Runtime: [Claude | Codex | Gemini]
Auditors: [Auditor A] + [Auditor B]

[Auditor A]: [VERDICT] ([SEVERITY])
[Auditor B]: [VERDICT] ([SEVERITY])

ARBITER DECISION: [APPROVE | APPROVE WITH CONDITIONS | REJECT | BLOCKED]

REASONING:
[Current agent explanation: which concerns are valid, why, what must be fixed]

KEY ISSUES:
- [Issue 1 with line reference]
- [Issue 2 with line reference]

REQUIRED ACTIONS:
- [What must be fixed before approval]

BLOCKERS:
- [Auth/tooling blocker, if the tribunal could not run]
```

### 9. Independence Guarantee

Auditors must not see each other's output.

- Run both selected commands in parallel when the host can do that.
- Use separate captured outputs or separate temp files: `/tmp/tribunal-claude.txt`, `/tmp/tribunal-codex.txt`, `/tmp/tribunal-gemini.txt`.
- The arbiter reads both outputs only after both complete.
- Do not include one auditor's verdict in the other's prompt.
- Do not reuse the current agent as an external auditor.

This prevents groupthink and keeps the review provider-relative across Claude, Codex, and Gemini runtimes.

## When to Use

Ideal for:

- Security-sensitive code: auth, payment, crypto, data access
- Refactoring with unclear impact
- Code review before merge to main
- Critical bug fixes
- Third-party code integration
- Before production deploy

Not needed for:

- Trivial changes: formatting, typos
- Documentation updates
- Configuration changes
- Test code unless security-relevant

Critical mode triggers:

- Production database migrations
- Authentication/authorization logic
- Payment processing
- Cryptographic operations
- Privilege escalation paths
- External API integrations with secrets

## Cost & Timing

| Runtime | Standard auditors | Critical auditors | Duration |
|---------|-------------------|-------------------|----------|
| Claude | Codex high + Gemini Flash | Codex xhigh + Gemini Pro | Parallel: max of both |
| Codex | Claude Sonnet + Gemini Flash | Claude Opus/Sonnet-high + Gemini Pro | Parallel: max of both |
| Gemini | Claude Sonnet + Codex high | Claude Opus/Sonnet-high + Codex xhigh | Parallel: max of both |

## Example Session

```text
User: /tribunal src/auth/session.py

Current runtime: Codex
Launching tribunal: Claude (sonnet) + Gemini (gemini-3-flash-preview)

TRIBUNAL VERDICT

Runtime: Codex
Auditors: Claude + Gemini

Claude: CONCERNS (MEDIUM)
- Line 47: Exception handling hides async failure details
- Line 112: No explicit timeout on external model call

Gemini: APPROVE (LOW)
- Minor: Could add retry logic for transient errors

ARBITER DECISION: APPROVE WITH CONDITIONS

REASONING:
Claude identified a real production-hardening issue. Gemini's approval is compatible with this because the concern is not a correctness blocker for the current path.

REQUIRED ACTIONS:
- Add explicit timeout around the external model call before production rollout.
```

## Anti-patterns

Don't:

- Read one auditor's output before launching the other.
- Include one auditor's verdict in the other's prompt.
- Auto-approve on a single approval.
- Skip arbiter synthesis.
- Use the current runtime as one of its own auditors.
- Silently proceed when a selected auditor is not logged in.
- Use tribunal for every trivial change.

Do:

- Select auditors relative to the current runtime.
- Run the two external auditors in parallel when the host can do that.
- Use identical prompts for both.
- Read both verdicts before deciding.
- Explain disagreements in synthesis.
- Escalate to critical mode for security-sensitive code.

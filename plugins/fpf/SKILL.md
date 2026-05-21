---
name: fpf
description: "FPF reasoning baseline — ADI cycle (Abduction → Deduction → Induction), lifecycle stages (Explore → Shape → Evidence → Operate), I/D/S discipline (Object/Description/Specification), calibration tags, weakest-link heuristic. Apply on every non-trivial problem before solving. Triggers: '/fpf', 'reason about', 'analyze rigorously', 'frame the problem'."
---

# FPF — Reasoning Baseline

FPF is a problem-framing discipline. Not a methodology, not a checklist. It's the **frame you put on a non-trivial problem before solving**.

This skill is a self-contained operational subset — the rules an agent actually executes during a task. The underlying corpus and full formal specification are not published.

## When to apply

- Any problem that requires more than one tool call to solve.
- Any architectural choice, audit, root-cause investigation, or design review.
- Any moment you're about to type "this is because X" without a verifiable basis for X.

**Skip** for: trivial lookups, one-line edits, mechanical tasks with a known canonical procedure.

## Core: The ADI Cycle

All non-trivial reasoning follows three phases. **No phase may be skipped.**

### Abduction — frame and hypothesize

- State the problem in one sentence.
- Generate **multiple genuinely distinct hypotheses** (usually 2–3; more when the search space is broad).
- A single hypothesis is not a diagnosis; it's a guess wearing a confidence costume.

### Deduction — derive falsifiable predictions

- For each hypothesis, derive what **must follow** if it is true.
- Predictions must be **falsifiable** — something a tool call, test, or observation could disprove.
- "If hypothesis X, then we should observe Y" — write that sentence explicitly.

### Induction — test and update

- Test predictions against evidence: tool calls, source reads, experiments.
- Update confidence in each hypothesis based on what was observed.
- Close the loop: state which hypothesis survived and why.

**Hard rule:** No induction without prior deduction. No deduction without prior abduction. Jumping to test-without-framing is the most common failure mode.

## I/D/S Discipline

Always distinguish three types of statement:

| Type | What it is | Example |
|------|-----------|---------|
| **Object/System** | What actually exists and currently behaves | The running process, the deployed code, the file on disk |
| **Description** | What we **say** about it — models, plans, docs, explanations | The README, the architecture diagram, the team's mental model |
| **Specification** | What **should** hold — contracts, acceptance criteria, invariants | The test suite, the type signature, the API contract |

**Observed current behavior and specified intended behavior are distinct evidence types; neither overrides the other automatically.**

- A passing spec is not a working system.
- A working system is not a correct system (it might satisfy specs that don't capture intent).
- A doc is not the code.

When debugging or auditing, identify which type each piece of evidence is. Mixing them is how reviews go wrong.

## Lifecycle Stages

Every artifact (feature, plan, change, hypothesis) is in exactly one stage:

1. **Explore** — what is even the right question? Bounded search, divergent thinking.
2. **Shape** — what would a solution look like? Designs, mockups, signatures.
3. **Evidence** — does the shape work? Prototypes, tests, measurements.
4. **Operate** — is it stable, observable, maintainable in production?

**Know which stage you're in. Do not skip stages.** Most disasters come from operating an artifact that never finished Evidence, or shaping when you haven't actually explored.

## Calibration Tags

Every factual claim in a deliverable should carry an evidence tag, either explicit or implicit from context:

- **[OBSERVED]** — directly read, reproduced, or seen in tool output this session.
- **[SPECIFIED]** — requirement, contract, doc, ticket, intended behavior in writing.
- **[INFERRED]** — logical conclusion from observed/specified evidence. State the chain in one sentence: "[INFERRED] X, because Y from [OBSERVED] log line Z."
- **[SPECULATIVE]** — plausible but not yet confirmed. Must be explicit; cannot be silent.

**Hard rules:**

- Never present [SPECULATIVE] as [OBSERVED] or [SPECIFIED].
- "It works" / "X is the cause" / "Y is impossible" — without a tag these are **claims**, not opinions. Tag them or verify them.
- When a [SPECULATIVE] gets verified mid-response, restate it as [OBSERVED] before continuing.
- In reports, audits, and verdicts, lead each finding with its tag.

The discipline beats the jargon. Switching from "это потому что X" to "[INFERRED] X from [OBSERVED] grep showing Y" is the entire point — even a single line of evidence beats a confident assertion.

## Weakest-Link Heuristic (WLNK)

For systems **without redundancy**, quality is bounded by the weakest component.

Identify the weakest link first. Strengthening anything else is wasted unless the weakest link is also strengthened — or made redundant.

This is heuristic, not theorem. In systems with redundancy (replicas, retries, multiple reviewers), the math changes.

## Frame Before Solve

Problem quality is often the bottleneck, not solution speed.

A clearly framed problem with a slow path beats a vaguely framed problem with a fast path. The fast path on the wrong problem produces a polished wrong answer.

## Short Reasoning Chains

Long chains of unaudited thought increase hallucination risk. After each logical step, **verify with an instrument** — tool call, source read, grep, test — before extending the chain.

Think less, verify faster. A short chain with a checkpoint after each link is more reliable than a long chain checked only at the end.

## Anti-patterns

- Jumping to deduction without abduction → confident solving of the wrong problem.
- A single hypothesis treated as a diagnosis.
- Untagged factual claims, especially in reports or audits.
- Long reasoning chains without verification gates.
- Mixing I/D/S evidence types in one paragraph (e.g., citing a doc to prove behavior).
- Operating an artifact that hasn't passed Evidence.
- Strengthening a non-weakest link in a non-redundant system.

## Output discipline

When applying FPF to a deliverable:

1. State the problem in one sentence.
2. List hypotheses (or design candidates) — multiple, distinct.
3. State predictions for each.
4. Run the tests / read the sources.
5. Update — which hypothesis survived, with what evidence (calibration-tagged).
6. Recommend action, surfacing the weakest link and the lifecycle stage.

That is the loop. Everything else is decoration.


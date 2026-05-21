---
name: fpf
description: "FPF reasoning baseline — ADI cycle (Abduction → Deduction → Induction), lifecycle stages (Explore → Shape → Evidence → Operate), I/D/S discipline (Object/Description/Specification), calibration tags, weakest-link heuristic. Apply on every non-trivial problem before solving. Triggers: '/fpf', 'reason about', 'analyze rigorously', 'frame the problem'."
---

# FPF — Reasoning Baseline

FPF (First Principles Framework) is a problem-framing discipline by [Anatoly Levenchuk](https://github.com/ailev). Not a methodology, not a checklist — the **frame you put on a non-trivial problem before solving**.

This SKILL.md captures the always-loaded operational subset — the rules an agent executes during a task. For exact wording, modules, and cross-references, the plugin also ships a builder that pulls the upstream `ailev/FPF` spec and modularizes it locally on demand. See [Corpus — deep dive into the spec](#corpus--deep-dive-into-the-spec) below.

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

## Corpus — deep dive into the spec

For exact wording, full cross-references, or specific module text, run the bundled builder:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/refresh.sh"
```

First call fetches the upstream `ailev/FPF` spec (~7MB), splits it into modules, cards, a relation graph, and four agent navigation files. Subsequent calls are a silent no-op when upstream hasn't moved (it caches the upstream commit SHA in `<corpus>/.upstream-sha` and compares before doing any work).

Requirements: `python3` (stdlib only) and `curl`. No FPF text is bundled in the plugin itself — the corpus is built fresh on each user's machine against the latest `ailev/FPF`.

After the build, the corpus lives at `${CLAUDE_PLUGIN_ROOT}/corpus/` by default (override with `FPF_CORPUS_DIR=…` or pass as first arg). Layout:

```text
corpus/
├── source/FPF-Spec.md        # canonical upstream text (fetched at the cached SHA)
├── modules/                  # lossless section views with YAML frontmatter
├── cards/                    # navigation cards (one per section)
├── graph/                    # relation edges (builds_on, refines, …)
└── agent/
    ├── load-policy.md        # navigation rules
    ├── entrypoints.yaml      # curated route hints for common tasks
    ├── glossary.yaml         # compact term → module-id map
    └── query-index.jsonl     # one compact search row per module
```

### Load policy

Use FPF without loading the full source:

1. Start with `corpus/agent/entrypoints.yaml`, `glossary.yaml`, and `query-index.jsonl`.
2. Select 1–5 candidate cards by trigger, keyword, title, or query match.
3. Read only matching `corpus/cards/**/*.card.yaml`.
4. Load a full `corpus/modules/**/*.md` file only when exact wording, checklist, or rationale is needed.
5. Expand the graph one hop at a time through `builds_on`, `refines`, and `coordinates_with`.
6. Cards = navigation. Modules = evidence. `source/FPF-Spec.md` = canonical.
7. Cite module id plus source span when using FPF in a decision.

### Periodic refresh

Re-run `refresh.sh` to check upstream and rebuild if it has moved. The script makes one cheap GitHub API call to read the current `main` commit SHA; if it matches the cached SHA, it exits silently. Reasonable cadence: once per session before doing deep FPF work, or whenever upstream announces a new version. Force a rebuild regardless of SHA match with `FPF_FORCE=1`.

Corpus schema: `s5d.fpf-corpus/0.1`. Each module carries YAML frontmatter with `id`, source span, source hash, and inferred relations. The relation graph is extracted from explicit `Builds on`, `Refines`, `Prerequisite for`, `Coordinates with`, `Tracks`, and `Tooling for` markers in the source text.

## Further reading

- **Original FPF spec** — <https://github.com/ailev/FPF>. Anatoly Levenchuk's First Principles Framework: pattern language and core specification for admissible action in engineering, research, and mixed human/AI work. The canonical source the bundled builder pulls from.
- **`m0n0x41d/claude-code-fpf`** — separate public Claude Code skill that ships the FPF spec as an embedded SQLite/FTS5 index plus an `fpf-rag` Go binary. Different access pattern: CLI-tool query rather than markdown navigation. Pick whichever fits your workflow.

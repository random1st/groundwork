---
name: fpf-modules
description: "Local builder for an agent-navigable modular FPF corpus. Fetches the upstream spec from ailev/FPF, splits it into modules, cards, and a relation graph, generates agent navigation files (entrypoints, glossary, query-index). Use when you need on-demand deep search over the full FPF specification without bundling its text. Triggers: '/fpf-modules', 'fpf corpus', 'fpf deep search', 'fpf module', 'fpf card', 'fpf relation'."
---

# FPF Modules — Local Corpus Builder

This skill turns the upstream [FPF](https://github.com/ailev/FPF) spec into a structured corpus that an agent can navigate without loading the full source. The FPF text itself is **not bundled** — the builder fetches it fresh from upstream on demand, so you always have the latest spec and no derivative work is redistributed by this plugin.

The companion plugin `fpf` ships the always-on operational baseline (ADI, calibration tags, I/D/S). `fpf-modules` is the deep-dive: navigate, search, cite specific modules.

## First-time setup

Build the corpus once. It writes to `<plugin-root>/corpus/` by default; subsequent runs refresh against the latest upstream.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/build.sh"
```

Requirements: `python3` (stdlib only — no extra packages) and `curl`.

To build into a custom path:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/build.sh" /path/to/fpf-corpus
```

After the build, the corpus layout is:

```text
corpus/
├── source/
│   └── FPF-Spec.md           # canonical upstream text (fetched fresh)
├── modules/                  # lossless section views with YAML frontmatter
├── cards/                    # navigation cards (one per section)
├── graph/                    # relation edges (builds_on, refines, ...)
└── agent/
    ├── load-policy.md        # navigation rules (read first)
    ├── entrypoints.yaml      # curated route hints for common tasks
    ├── glossary.yaml         # compact term → module-id map
    └── query-index.jsonl     # one compact search row per module
```

## Load Policy

Use FPF without loading the full source:

1. Start with `corpus/agent/entrypoints.yaml`, `agent/glossary.yaml`, and `agent/query-index.jsonl`.
2. Select 1–5 candidate cards by trigger, keyword, title, or query match.
3. Read only matching `corpus/cards/**/*.card.yaml`.
4. Load a full `corpus/modules/**/*.md` file only when exact wording, checklist, or rationale is needed.
5. Expand the graph one hop at a time through `builds_on`, `refines`, and `coordinates_with`.
6. Treat cards as navigation. Treat modules as evidence. Treat `source/FPF-Spec.md` as canonical.
7. Cite module id plus source span when using FPF in a decision.

## Refresh

Re-run `build.sh` whenever upstream `ailev/FPF` ships a new spec version. The script always pulls the latest `main`, runs `fpf_modularize.py` with `--clean`, and rebuilds the entire corpus deterministically.

## Schema

The corpus schema is `s5d.fpf-corpus/0.1`. Each module carries YAML frontmatter with `id`, source span, hash, and inferred relations. Each card carries the same metadata in a navigation-oriented shape. The relation graph is inferred from explicit `Builds on`, `Refines`, `Prerequisite for`, `Coordinates with`, `Tracks`, `Tooling for` markers in the source text.

## Attribution

Underlying spec: **[`ailev/FPF`](https://github.com/ailev/FPF)** — *First Principles Framework* by Anatoly Levenchuk. Modules, cards, and the graph are computed locally from that source. This plugin redistributes no FPF text — only the modularization script and navigation conventions.

## Companion plugins

- **`fpf`** — operational baseline (ADI cycle, calibration tags). Always loaded.
- **`m0n0x41d/claude-code-fpf`** — separate public skill with an embedded SQLite/FTS5 index over the spec, exposed via an `fpf-rag` Go binary. Different access pattern: query via a CLI tool rather than reading markdown files. Pick whichever fits your workflow.

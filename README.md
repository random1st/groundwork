# random1st / claude-plugins

Personal Claude Code plugin marketplace.

Reasoning, audit, and meta-workflow skills extracted from a working dev/AI stack. No coupling to my personal runtime — each plugin uses raw CLIs (`claude`, `codex`, `gemini`) or standard Claude Code conventions.

## Install

```text
/plugin marketplace add random1st/claude-plugins
/plugin install <plugin-name>@random1st-plugins
```

Update the marketplace later:

```text
/plugin marketplace update random1st-plugins
```

## Plugins

| Plugin | What it is |
|--------|-----------|
| [tribunal](plugins/tribunal/) | Provider-relative independent audit. Current agent arbitrates; the two other CLIs review in parallel. For security-sensitive code, pre-merge gates, critical bug fixes. |
| [delegate](plugins/delegate/) | Unified external AI delegation — Codex or Gemini, by cost/quality tradeoff. |
| [fpf](plugins/fpf/) | FPF reasoning baseline — ADI cycle, lifecycle stages, I/D/S, calibration tags. The operational excerpt of the full FPF corpus. |
| [verify](plugins/verify/) | Force verification before claiming completion. Evidence before assertions. |
| [systematic-debugging](plugins/systematic-debugging/) | Root-cause-first debugging methodology. Four phases, no fixes without investigation. |
| [dispatching-parallel-agents](plugins/dispatching-parallel-agents/) | Pattern for splitting independent investigations across parallel agents. |
| [scratchpad](plugins/scratchpad/) | Persistent working memory for multi-iteration tasks. |
| [skill-creator](plugins/skill-creator/) | Guide and scripts for creating effective Claude Code skills. |
| [create-agents](plugins/create-agents/) | Create Claude Code agents — autonomous workers with isolated context and restricted tools. |

## Template: CLAUDE.md

The marketplace also ships a cleaned, project-agnostic [CLAUDE.md template](templates/CLAUDE.md) — the working reasoning/calibration/protocol discipline behind these plugins. Drop into `~/.claude/CLAUDE.md` and edit to taste.

## Prerequisites

`tribunal` and `delegate` shell out to `codex` and `gemini` CLIs. Install and authenticate them before use:

- [`codex`](https://github.com/openai/codex) — OpenAI Codex CLI
- [`gemini`](https://github.com/google-gemini/gemini-cli) — Google Gemini CLI

Other plugins are pure guidance and need no external tooling.

## Layout

```text
.
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── tribunal/
│   ├── delegate/
│   ├── fpf/
│   ├── verify/
│   ├── systematic-debugging/
│   ├── dispatching-parallel-agents/
│   ├── scratchpad/
│   ├── skill-creator/
│   └── create-agents/
└── templates/
    └── CLAUDE.md
```

Each plugin is a single SKILL.md (or SKILL.md + bundled scripts/references) plus `.claude-plugin/plugin.json`.

## License

MIT for marketplace-original content. Individual plugins may carry their own licenses where they bundle third-party material:

- `plugins/skill-creator/` carries Apache 2.0 (from the original Anthropic `skill-creator`).

See per-plugin LICENSE files where present.

## Related

- Full FPF corpus (222 modules, formal spec): <https://github.com/system5-dev/s5d>

#!/usr/bin/env bash
# Build a local modular FPF corpus from the upstream ailev/FPF spec.
#
# Usage:
#   bash build.sh [output-dir]
#
# Default output-dir is "<plugin-root>/corpus".
# Re-run to refresh the corpus against the latest upstream FPF-Spec.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
OUT_DIR="${1:-$PLUGIN_ROOT/corpus}"
SOURCE_DIR="$OUT_DIR/source"
SOURCE_FILE="$SOURCE_DIR/FPF-Spec.md"
UPSTREAM_URL="https://raw.githubusercontent.com/ailev/FPF/main/FPF-Spec.md"

command -v python3 >/dev/null 2>&1 || { echo "fpf-modules: python3 is required" >&2; exit 1; }
command -v curl    >/dev/null 2>&1 || { echo "fpf-modules: curl is required"    >&2; exit 1; }

mkdir -p "$SOURCE_DIR"

echo "→ Fetching upstream FPF-Spec.md from ailev/FPF..."
curl -fsSL "$UPSTREAM_URL" -o "$SOURCE_FILE"

bytes="$(wc -c < "$SOURCE_FILE" | tr -d ' ')"
echo "  fetched: $bytes bytes → $SOURCE_FILE"

echo "→ Modularizing into $OUT_DIR ..."
python3 "$SCRIPT_DIR/fpf_modularize.py" "$SOURCE_FILE" --out "$OUT_DIR" --clean

echo
echo "Done. Navigate the corpus starting from:"
echo "  $OUT_DIR/agent/entrypoints.yaml"
echo "  $OUT_DIR/agent/glossary.yaml"
echo "  $OUT_DIR/agent/query-index.jsonl"

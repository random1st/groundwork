#!/usr/bin/env bash
# Refresh the local FPF corpus against upstream ailev/FPF.
#
# Behaviour:
#   - Resolves the current ailev/FPF main commit SHA via GitHub.
#   - Compares against the cached SHA in <corpus>/.upstream-sha.
#   - If the SHA matches AND the corpus is present, exits silently (no work).
#   - Otherwise fetches FPF-Spec.md at that SHA and runs fpf_modularize.py
#     with --clean. Records the new SHA on success.
#
# Designed to be a fast no-op when nothing has changed — safe to call on
# every session start or before any deep FPF query.
#
# Usage:
#   bash refresh.sh                       # default corpus path
#   bash refresh.sh /custom/corpus/dir    # custom output
#   FPF_FORCE=1 bash refresh.sh           # rebuild even if SHA matches
#   FPF_QUIET=1 bash refresh.sh           # suppress info messages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
CORPUS_DIR="${1:-${FPF_CORPUS_DIR:-$PLUGIN_ROOT/corpus}}"
SHA_FILE="$CORPUS_DIR/.upstream-sha"
UPSTREAM_REPO="ailev/FPF"
UPSTREAM_BRANCH="main"
SPEC_PATH="FPF-Spec.md"

log() { [ "${FPF_QUIET:-0}" = "1" ] || echo "$@"; }

command -v python3 >/dev/null 2>&1 || { echo "fpf: python3 is required" >&2; exit 1; }
command -v curl    >/dev/null 2>&1 || { echo "fpf: curl is required"    >&2; exit 1; }

get_upstream_sha() {
  if command -v gh >/dev/null 2>&1; then
    gh api "repos/$UPSTREAM_REPO/commits/$UPSTREAM_BRANCH" --jq '.sha' 2>/dev/null && return 0
  fi
  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$UPSTREAM_REPO/commits/$UPSTREAM_BRANCH" 2>/dev/null \
    | python3 -c "import sys, json; print(json.load(sys.stdin)['sha'])"
}

upstream_sha="$(get_upstream_sha || true)"
if [ -z "${upstream_sha:-}" ]; then
  echo "fpf: could not reach upstream ailev/FPF (offline or rate-limited)" >&2
  exit 1
fi

cached_sha=""
[ -f "$SHA_FILE" ] && cached_sha="$(cat "$SHA_FILE" 2>/dev/null || true)"

if [ "${FPF_FORCE:-0}" != "1" ] && [ "$upstream_sha" = "$cached_sha" ] && [ -d "$CORPUS_DIR/agent" ]; then
  log "fpf: corpus up to date (ailev/FPF@${upstream_sha:0:7})"
  exit 0
fi

short_cached="${cached_sha:0:7}"
log "fpf: refreshing corpus from ailev/FPF@${upstream_sha:0:7} (was: ${short_cached:-none})..."

mkdir -p "$CORPUS_DIR/source"
SOURCE_FILE="$CORPUS_DIR/source/FPF-Spec.md"
curl -fsSL "https://raw.githubusercontent.com/$UPSTREAM_REPO/$upstream_sha/$SPEC_PATH" -o "$SOURCE_FILE"

python3 "$SCRIPT_DIR/fpf_modularize.py" "$SOURCE_FILE" --out "$CORPUS_DIR" --clean

echo "$upstream_sha" > "$SHA_FILE"
log "fpf: corpus rebuilt → $CORPUS_DIR"

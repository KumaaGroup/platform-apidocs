#!/usr/bin/env bash
# SessionStart hook (copied into each repo as .claude/hooks/session-start.sh).
# Syncs KumaaGroup/central-ai into the gitignored .claude-central/ directory, prints the general rules
# and this repo's always-on files to stdout (Claude Code injects stdout as session context), and
# links this repo's path-scoped rules into .claude/rules/_central/. On failure it prints a loud notice
# instead; the PreToolUse guard then refuses edits until the sync succeeds.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0
REPO=$(basename -s .git "$(git remote get-url origin 2>/dev/null)")
DIR=".claude-central"
REMOTE="${CENTRAL_AI_REMOTE:-https://github.com/KumaaGroup/central-ai.git}"
fail() {
  rm -f "$DIR/.ok"
  echo "CENTRAL RULES NOT LOADED for repo '$REPO': $1. Do not change any file until this is fixed. Tell the user to run: gh repo clone KumaaGroup/central-ai $ROOT/$DIR (or fix the existing clone), then restart the session."
  echo "central-ai: $1" >&2
  exit 0
}
# Claude Code passes the session on stdin; inject once per session even if this hook is registered
# twice (a repo's own .claude/settings.json and the CI reviewer's settings both register it).
SID=""
if [ ! -t 0 ]; then SID=$(timeout 2 python3 -c 'import sys,json; print(json.load(sys.stdin).get("session_id",""))' 2>/dev/null || true); fi
if [ -n "$SID" ] && [ -f "$DIR/.injected-$SID" ]; then
  echo "central-ai rules already injected in this session."; exit 0
fi
if [ -d "$DIR/.git" ]; then
  git -C "$DIR" pull -q --ff-only origin main 2>/dev/null || echo "central-ai: pull failed, using the last synced copy" >&2
else
  git clone -q --depth 1 "$REMOTE" "$DIR" 2>/dev/null || fail "clone failed (no network or no access to KumaaGroup/central-ai)"
fi
[ -f "$DIR/manifest.txt" ] || fail "manifest.txt missing in the synced copy"
rm -rf .claude/rules/_central && mkdir -p .claude/rules/_central
echo "=== KumaaGroup general rules (central-ai/general, every repo) ==="
for f in "$DIR"/general/*.md; do echo; echo "--- $(basename "$f")"; cat "$f"; done
echo; echo "=== Rules for repo: $REPO ==="
found=0
while read -r r kind path; do
  case "$r" in ''|'#'*) continue;; esac
  [ "$r" = "$REPO" ] || continue
  found=1
  case "$kind" in
    doc)   echo; echo "--- $path"; cat "$DIR/$path";;
    rules) if [ -f "$DIR/$path" ]; then ln -s "../../../$DIR/$path" ".claude/rules/_central/$(basename "$path")"; else for rf in "$DIR/$path"/*.md; do [ -e "$rf" ] && ln -s "../../../$DIR/$path/$(basename "$rf")" ".claude/rules/_central/$(basename "$rf")"; done; fi;;
  esac
done < "$DIR/manifest.txt"
[ "$found" = 1 ] || echo "(no repo-specific entries in manifest.txt for '$REPO'; general rules only)"
echo; echo "Path-scoped rules are linked under .claude/rules/_central/ and load when matching files are read."
touch "$DIR/.ok"
[ -n "$SID" ] && touch "$DIR/.injected-$SID"
find "$DIR" -maxdepth 1 -name ".injected-*" -mmin +1440 -delete 2>/dev/null

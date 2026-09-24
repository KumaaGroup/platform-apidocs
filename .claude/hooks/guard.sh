#!/usr/bin/env bash
# PreToolUse guard for Edit|Write|MultiEdit (copied into each repo as .claude/hooks/guard.sh).
# Exit 2 blocks the tool call and feeds stderr back to Claude.
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -f "$ROOT/.claude-central/.ok" ] && exit 0
echo "Blocked: central rules are not loaded (.claude-central/.ok missing). Ask the user to clone KumaaGroup/central-ai into .claude-central/ and restart the session." >&2
exit 2

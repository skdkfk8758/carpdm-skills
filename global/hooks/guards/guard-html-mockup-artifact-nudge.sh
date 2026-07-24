#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): Nudge Artifact publish after writing an HTML mockup.
# Non-blocking — the hook cannot know whether Artifact was called; the AI reading
# ~/.claude/rules-ondemand/html-mockup-artifact.md does the actual enforcement.
# Disable: GUARD_HTML_ARTIFACT_NUDGE_DISABLE=1

[ "${GUARD_HTML_ARTIFACT_NUDGE_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

[ -z "$FILE_PATH" ] && exit 0

# Mockup path patterns: docs/plans/**.html, .planning/**.html, *-mockup.html, *-erd.html
if echo "$FILE_PATH" | grep -qE '(docs/plans/[^"]*\.html|\.planning/[^"]*\.html|-mockup\.html|-erd\.html)$'; then
  echo "[guard-html-mockup-artifact] HTML 시안 감지: ${FILE_PATH##*/} — Artifact 도구로 publish 하고 사용자에게 artifact URL 을 딜리버러블로 제시할 것 (로컬 파일은 유지). SSOT: ~/.claude/rules-ondemand/html-mockup-artifact.md" >&2
fi

exit 0

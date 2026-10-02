#!/usr/bin/env bash
# Runs the hook against fake inputs. Uses a temporary state dir: touches nothing in ~/.claude.
set -u
hook="$(cd "$(dirname "$0")" && pwd)/hooks/emoji-session-title.sh"
export EMOJI_TITLE_STATE_DIR="$(mktemp -d)"
tmp="$(mktemp -d)"; fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1 (got '$3', want '$2')"; fail=1; fi; }

out="$(echo '{"session_id":"s1","transcript_path":"/nonexistent"}' | "$hook" | jq -r '.hookSpecificOutput.hookEventName')"
check "new session -> asks for rename" "UserPromptSubmit" "$out"

out="$(echo '{"session_id":"s1","transcript_path":"/nonexistent"}' | "$hook")"
check "same session, 2nd prompt -> nothing" "" "$out"

echo '{"type":"user","message":{"content":[{"type":"text","text":"hi"}]}}' > "$tmp/t.jsonl"
out="$(jq -n --arg t "$tmp/t.jsonl" '{session_id:"s2",transcript_path:$t}' | "$hook")"
check "resumed session -> nothing" "" "$out"

echo '{"type":"user","message":{"content":[{"type":"tool_result","content":"x"}]}}' > "$tmp/t2.jsonl"
out="$(jq -n --arg t "$tmp/t2.jsonl" '{session_id:"s3",transcript_path:$t}' | "$hook" | jq -r '.hookSpecificOutput.hookEventName')"
check "tool results are not prompts" "UserPromptSubmit" "$out"

echo '{"type":"user","message":{"content":"<command-name>/model</command-name>"}}' > "$tmp/t3.jsonl"
out="$(jq -n --arg t "$tmp/t3.jsonl" '{session_id:"s4",transcript_path:$t}' | "$hook" | jq -r '.hookSpecificOutput.hookEventName')"
check "slash command before 1st prompt -> still renames" "UserPromptSubmit" "$out"

rm -rf "$EMOJI_TITLE_STATE_DIR" "$tmp"; exit $fail

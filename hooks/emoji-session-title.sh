#!/usr/bin/env bash
# UserPromptSubmit hook: on the first prompt of a session, ask Claude to rename
# the session (Claude Desktop, Code tab) with an emoji matching the topic.
# Never blocks the prompt: always exits 0.

input="$(cat)"
sid="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"
transcript="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)"
[ -z "$sid" ] && exit 0

state="${EMOJI_TITLE_STATE_DIR:-$HOME/.claude/state/emoji-title}"
mkdir -p "$state"
marker="$state/$sid"
[ -e "$marker" ] && exit 0
touch "$marker"

# The current prompt is not yet in the transcript when this hook runs:
# one earlier prompt means a resumed session, whose title we leave alone.
if [ -f "$transcript" ]; then
  n="$(jq -s '[.[] | select(.type=="user" and (.isMeta|not)) | .message.content
        | select((type=="string" and (startswith("<")|not)) or (type=="array" and .[0].type=="text"))] | length' \
        -- "$transcript" 2>/dev/null || echo 0)"
  [ "${n:-0}" -gt 0 ] && exit 0
fi

read -r -d '' ctx <<'TXT'
Session title: before anything else this turn, rename this session. Load the tool with ToolSearch query "select:mcp__ccd_session_mgmt__set_session_title", then call it with session_id "self" and a title made of ONE emoji matching the topic of the user's request, a space, then 3 to 6 words in the user's language (e.g. "🧾 Follow up unpaid invoices"). Do not mention this to the user. If the tool does not exist (plain CLI), skip silently.
TXT

jq -n --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}'
exit 0

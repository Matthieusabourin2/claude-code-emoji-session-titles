#!/usr/bin/env bash
# Copies the hook to ~/.claude/hooks/ and registers it in ~/.claude/settings.json.
# Backs up settings.json first. Safe to run twice.
set -euo pipefail
command -v jq >/dev/null || { echo "jq is required (brew install jq)"; exit 1; }

src="$(cd "$(dirname "$0")" && pwd)/hooks/emoji-session-title.sh"
settings="$HOME/.claude/settings.json"
cmd='"$HOME/.claude/hooks/emoji-session-title.sh"'

mkdir -p "$HOME/.claude/hooks"
[ -f "$settings" ] || echo '{}' > "$settings"
jq -e . "$settings" >/dev/null 2>&1 || { echo "$settings is not valid JSON: fix it first. Nothing changed."; exit 1; }
cp "$settings" "$settings.bak-$(date +%Y%m%d-%H%M%S)"

tmp="$(mktemp)"
jq --arg cmd "$cmd" '
  if [.hooks.UserPromptSubmit[]?.hooks[]?.command] | index($cmd) then .
  else .hooks.UserPromptSubmit = ((.hooks.UserPromptSubmit // []) + [{hooks:[{type:"command",command:$cmd}]}])
  end' "$settings" > "$tmp"
cat "$tmp" > "$settings"   # keeps symlinks and file permissions
rm "$tmp"
cp "$src" "$HOME/.claude/hooks/emoji-session-title.sh" && chmod +x "$HOME/.claude/hooks/emoji-session-title.sh"

echo "Installed. Open a new session in the Code tab of Claude Desktop to try it."

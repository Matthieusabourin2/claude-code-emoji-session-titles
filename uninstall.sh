#!/usr/bin/env bash
# Removes the hook from ~/.claude/settings.json (backup first) and deletes the script.
set -euo pipefail
settings="$HOME/.claude/settings.json"
cmd='"$HOME/.claude/hooks/emoji-session-title.sh"'

if [ -f "$settings" ]; then
  jq -e . "$settings" >/dev/null 2>&1 || { echo "$settings is not valid JSON: fix it first. Nothing changed."; exit 1; }
  cp "$settings" "$settings.bak-$(date +%Y%m%d-%H%M%S)"
  tmp="$(mktemp)"
  jq --arg cmd "$cmd" '
    if .hooks.UserPromptSubmit then .hooks.UserPromptSubmit |= map(.hooks |= map(select(.command != $cmd)) | select(.hooks | length > 0)) else . end
    | if .hooks.UserPromptSubmit == [] then del(.hooks.UserPromptSubmit) else . end' "$settings" > "$tmp"
  cat "$tmp" > "$settings"
  rm "$tmp"
fi
rm -f "$HOME/.claude/hooks/emoji-session-title.sh"
echo "Uninstalled."

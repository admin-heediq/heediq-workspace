#!/usr/bin/env bash
set -euo pipefail

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_DIR="$WORKSPACE_ROOT/.claude"
TPL="$SCRIPT_DIR/settings.json.tpl"

echo "Workspace root : $WORKSPACE_ROOT"
echo "Claude config  : $CLAUDE_DIR"
echo ""

mkdir -p "$CLAUDE_DIR"

# Write team settings.json — always overwrite (canonical, sourced from repo)
sed "s|__WORKSPACE_ROOT__|$WORKSPACE_ROOT|g" "$TPL" > "$CLAUDE_DIR/settings.json"
echo "[ok] $CLAUDE_DIR/settings.json written"

# Write settings.local.json only if it does not exist (personal, not committed)
LOCAL="$CLAUDE_DIR/settings.local.json"
if [ ! -f "$LOCAL" ]; then
  cat > "$LOCAL" << ENDJSON
{
  "autoCompactEnabled": true,
  "permissions": {
    "allow": [
      "Bash(git add *)",
      "Bash(git commit -m ' *)",
      "Bash(git push *)",
      "Bash(git remote *)",
      "Bash(ssh -T git@github.com)",
      "Bash(gh auth *)",
      "Read($HOME/.ssh/**)"
    ]
  }
}
ENDJSON
  echo "[ok] $LOCAL created"
else
  echo "[skip] $LOCAL already exists — not overwritten"
fi

echo ""
echo "Done. Always launch Claude from the workspace root:"
echo "  cd $WORKSPACE_ROOT && claude"

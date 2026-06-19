#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# Heediq — Claude Workspace Setup
#
# Run this AFTER clone-repos.sh, from the workspace root:
#   bash claude-workspace/scripts/setup-workspace.sh
#
# What it does:
#   1. Writes the workspace-root CLAUDE.md (loads rules into Claude)
#   2. Configures .claude/ settings (team + personal)
#   3. Checks GitHub CLI authentication
#
# Prerequisite: clone-repos.sh already run (all repos present)
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo ""
echo "=== Heediq Workspace Setup ==="
echo "Workspace: $WORKSPACE_ROOT"
echo ""

# ---- 1. Write workspace-root CLAUDE.md -----------------------

echo "--- 1. Workspace root CLAUDE.md ---"
echo ""

ROOT_CLAUDE="$WORKSPACE_ROOT/CLAUDE.md"
if [[ -f "$ROOT_CLAUDE" ]]; then
  echo "  [skip] CLAUDE.md already exists"
else
  cat > "$ROOT_CLAUDE" << 'EOF'
# Heediq Workspace Root

This is the monorepo root. All Heediq project repos live as subdirectories here.

## Rules
All repos share the same rules defined in `claude-workspace`. A repo gets its own `CLAUDE.md` only
when it has rules that genuinely cannot apply workspace-wide.

## Memory
All memory lives in `claude-workspace/memory/` — business decisions, codebase index, dependency maps,
and per-repo codebase memory. Never split memory across repos.

@claude-workspace/CLAUDE.md
EOF
  echo "  [ok]   CLAUDE.md written"
fi

echo ""

# ---- 2. Configure .claude/ -----------------------------------

echo "--- 2. Claude Code settings ---"
echo ""

bash "$SCRIPT_DIR/setup-claude.sh"

echo ""

# ---- 3. Check GitHub CLI auth --------------------------------

echo "--- 3. GitHub CLI ---"
echo ""

if gh auth status &>/dev/null; then
  GH_USER=$(gh api user --jq .login 2>/dev/null || echo "authenticated")
  echo "  [ok]   gh CLI authenticated as ${GH_USER}"
else
  echo "  [!]  gh CLI not authenticated — needed for PR workflow."
  echo "       Run: gh auth login"
  echo "       Then re-run this script or continue manually."
fi

# ---- Done ----------------------------------------------------

echo ""
echo "=== Done ==="
echo ""
echo "Open Claude Code VS Code extension pointed at workspace root:"
echo "  $WORKSPACE_ROOT"
echo ""

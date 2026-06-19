#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# Heediq — New Machine Setup
#
# Run this ONCE from inside an empty workspace directory, AFTER
# cloning claude-workspace into it:
#
#   mkdir ~/dev/heediq && cd ~/dev/heediq
#   git clone git@github.com:heediq/claude-workspace.git   # or SSH alias
#   bash claude-workspace/scripts/setup-machine.sh
#
# What it does:
#   1. Clones all Heediq repos (skips repos that don't exist yet)
#   2. Writes the workspace-root CLAUDE.md
#   3. Configures .claude/ settings (team + personal)
#
# SSH alias: if ~/.ssh/config defines "Host github-heediq" the
# script uses it automatically. Otherwise falls back to github.com.
# Pass --https to use HTTPS cloning instead.
#
# Prerequisites (install before running):
#   - git
#   - Node.js 22 LTS  → https://nodejs.org
#   - pnpm            → npm install -g pnpm
#   - AWS CLI v2      → https://aws.amazon.com/cli/
#   - GitHub CLI (gh) → https://cli.github.com/
#   - Claude Code     → npm install -g @anthropic-ai/claude-code
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GITHUB_ORG="heediq"
USE_HTTPS=false

for arg in "$@"; do
  [[ "$arg" == "--https" ]] && USE_HTTPS=true
done

# All Heediq repos (excluding claude-workspace — already cloned to run this script)
REPOS=(
  "heediq-infra"
  "heediq-shared"
  "heediq-web"
  "heediq-api"
  "heediq-worker-transcription"
  "heediq-worker-summarization"
)

# ---- Determine clone base URL --------------------------------

if $USE_HTTPS; then
  BASE_URL="https://github.com/${GITHUB_ORG}"
elif grep -qE "^Host\s+github-heediq" "$HOME/.ssh/config" 2>/dev/null; then
  BASE_URL="git@github-heediq:${GITHUB_ORG}"
  echo "  [ssh] Using SSH alias 'github-heediq' from ~/.ssh/config"
else
  BASE_URL="git@github.com:${GITHUB_ORG}"
  echo "  [ssh] Using git@github.com (no 'github-heediq' alias found)"
fi

echo ""
echo "=== Heediq Machine Setup ==="
echo "Workspace: $WORKSPACE_ROOT"
echo ""

# ---- 1. Clone repos ------------------------------------------

echo "--- 1. Cloning repos ---"
echo ""

for repo in "${REPOS[@]}"; do
  dest="$WORKSPACE_ROOT/$repo"
  if [[ -d "$dest/.git" ]]; then
    echo "  [skip] $repo — already cloned"
  else
    echo "  cloning $repo ..."
    if git clone "${BASE_URL}/${repo}.git" "$dest" 2>/dev/null; then
      echo "  [ok]   $repo"
    else
      echo "  [skip] $repo — not found on remote (may not be scaffolded yet)"
    fi
  fi
done

echo ""

# ---- 2. Write workspace-root CLAUDE.md -----------------------

echo "--- 2. Workspace root CLAUDE.md ---"
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

# ---- 3. Configure .claude/ -----------------------------------

echo "--- 3. Claude Code settings ---"
echo ""

bash "$SCRIPT_DIR/setup-claude.sh"

# ---- Done ----------------------------------------------------

echo ""
echo "=== Done ==="
echo ""
echo "Next steps:"
echo "  1. Configure AWS SSO profiles (see heediq-infra/README.md → AWS CLI Profiles)"
echo "  2. Run AWS setup (CDK bootstrap + OIDC roles):"
echo "     cd $WORKSPACE_ROOT/heediq-infra && bash scripts/setup.sh"
echo "  3. Start Claude from the workspace root:"
echo "     cd $WORKSPACE_ROOT && claude"
echo ""

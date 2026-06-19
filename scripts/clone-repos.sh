#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# Heediq — Clone Repos
#
# Run from the workspace root AFTER cloning claude-workspace:
#
#   mkdir ~/dev/heediq && cd ~/dev/heediq
#   git clone git@github.com:heediq/claude-workspace.git
#   bash claude-workspace/scripts/clone-repos.sh
#
# What it does:
#   1. Verifies GitHub SSH connectivity (guides setup if missing)
#   2. Clones all Heediq repos into the workspace root
#      (skips repos that don't exist yet on GitHub)
#
# Options:
#   --https    Use HTTPS instead of SSH for cloning
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GITHUB_ORG="heediq"
USE_HTTPS=false

for arg in "$@"; do
  [[ "$arg" == "--https" ]] && USE_HTTPS=true
done

REPOS=(
  "heediq-infra"
  "heediq-shared"
  "heediq-web"
  "heediq-api"
  "heediq-worker-transcription"
  "heediq-worker-summarization"
)

echo ""
echo "=== Heediq — Clone Repos ==="
echo "Workspace: $WORKSPACE_ROOT"
echo ""

# ---- 1. SSH check (skip if using HTTPS) ----------------------

if ! $USE_HTTPS; then
  echo "--- 1. GitHub SSH ---"
  echo ""

  # Detect SSH alias
  if grep -qE "^Host\s+github-heediq" "$HOME/.ssh/config" 2>/dev/null; then
    SSH_HOST="github-heediq"
    echo "  Using SSH alias 'github-heediq' from ~/.ssh/config"
  else
    SSH_HOST="github.com"
  fi

  # Test connectivity
  SSH_RESULT=$(ssh -T "git@${SSH_HOST}" 2>&1 || true)
  if echo "$SSH_RESULT" | grep -q "successfully authenticated"; then
    echo "  [ok]   SSH authenticated with GitHub"
  else
    echo "  [!]  GitHub SSH authentication failed."
    echo ""
    echo "  Set up your SSH key:"
    echo "    1. Generate:  ssh-keygen -t ed25519 -C 'your@email.com'"
    echo "    2. Copy key:  cat ~/.ssh/id_ed25519.pub"
    echo "    3. Add to GitHub: https://github.com/settings/keys"
    echo "    4. Test:      ssh -T git@github.com"
    echo ""
    if [[ "$SSH_HOST" == "github-heediq" ]]; then
      echo "  You have a 'github-heediq' alias — make sure the key for that alias is added to"
      echo "  the heediq GitHub org account, not just your personal account."
      echo ""
    fi
    echo "  Once SSH is working, re-run this script."
    exit 1
  fi

  echo ""
  BASE_URL="git@${SSH_HOST}:${GITHUB_ORG}"
else
  echo "  [info] Using HTTPS cloning (--https flag)"
  BASE_URL="https://github.com/${GITHUB_ORG}"
fi

# ---- 2. Clone repos ------------------------------------------

echo "--- 2. Cloning repos ---"
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
      echo "  [skip] $repo — not on remote yet (will be scaffolded later)"
    fi
  fi
done

# ---- Done ----------------------------------------------------

echo ""
echo "=== Done ==="
echo ""
echo "Next: set up the Claude workspace:"
echo "  bash claude-workspace/scripts/setup-workspace.sh"
echo ""

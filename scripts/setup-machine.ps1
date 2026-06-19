#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =============================================================
# Heediq — New Machine Setup (Windows PowerShell)
#
# Run this ONCE from inside an empty workspace directory, AFTER
# cloning claude-workspace into it:
#
#   mkdir ~/dev/heediq; cd ~/dev/heediq
#   git clone git@github.com:heediq/claude-workspace.git
#   pwsh claude-workspace\scripts\setup-machine.ps1
#
# What it does:
#   1. Clones all Heediq repos (skips repos that don't exist yet)
#   2. Writes the workspace-root CLAUDE.md
#   3. Configures .claude\ settings (team + personal)
#
# Pass -Https to use HTTPS cloning instead of SSH.
#
# Prerequisites (install before running):
#   - git             → https://gitforwindows.org/
#   - Node.js 22 LTS  → https://nodejs.org
#   - pnpm            → npm install -g pnpm
#   - AWS CLI v2      → https://aws.amazon.com/cli/
#   - GitHub CLI (gh) → https://cli.github.com/
#   - Claude Code     → npm install -g @anthropic-ai/claude-code
#   - PowerShell 5.1+ (built-in) or PowerShell 7+ (recommended)
# =============================================================

param(
    [switch]$Https
)

$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$GithubOrg     = "heediq"

$Repos = @(
    "heediq-infra"
    "heediq-shared"
    "heediq-web"
    "heediq-api"
    "heediq-worker-transcription"
    "heediq-worker-summarization"
)

# ---- Determine clone base URL --------------------------------

$SshConfigPath = Join-Path $env:USERPROFILE ".ssh\config"
$HasAlias = $false
if (Test-Path $SshConfigPath) {
    $HasAlias = (Get-Content $SshConfigPath) -match '^\s*Host\s+github-heediq'
}

if ($Https) {
    $BaseUrl = "https://github.com/$GithubOrg"
} elseif ($HasAlias) {
    $BaseUrl = "git@github-heediq:$GithubOrg"
    Write-Host "  [ssh] Using SSH alias 'github-heediq' from ~/.ssh/config"
} else {
    $BaseUrl = "git@github.com:$GithubOrg"
    Write-Host "  [ssh] Using git@github.com (no 'github-heediq' alias found)"
}

Write-Host ""
Write-Host "=== Heediq Machine Setup ==="
Write-Host "Workspace: $WorkspaceRoot"
Write-Host ""

# ---- 1. Clone repos ------------------------------------------

Write-Host "--- 1. Cloning repos ---"
Write-Host ""

foreach ($Repo in $Repos) {
    $Dest = Join-Path $WorkspaceRoot $Repo
    if (Test-Path (Join-Path $Dest ".git")) {
        Write-Host "  [skip] $Repo — already cloned"
    } else {
        Write-Host "  cloning $Repo ..."
        $CloneResult = git clone "$BaseUrl/$Repo.git" $Dest 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [ok]   $Repo"
        } else {
            Write-Host "  [skip] $Repo — not found on remote (may not be scaffolded yet)"
        }
    }
}

Write-Host ""

# ---- 2. Write workspace-root CLAUDE.md -----------------------

Write-Host "--- 2. Workspace root CLAUDE.md ---"
Write-Host ""

$RootClaude = Join-Path $WorkspaceRoot "CLAUDE.md"
if (Test-Path $RootClaude) {
    Write-Host "  [skip] CLAUDE.md already exists"
} else {
    $ClaudeContent = @"
# Heediq Workspace Root

This is the monorepo root. All Heediq project repos live as subdirectories here.

## Rules
All repos share the same rules defined in ``claude-workspace``. A repo gets its own ``CLAUDE.md`` only
when it has rules that genuinely cannot apply workspace-wide.

## Memory
All memory lives in ``claude-workspace/memory/`` — business decisions, codebase index, dependency maps,
and per-repo codebase memory. Never split memory across repos.

@claude-workspace/CLAUDE.md
"@
    $ClaudeContent | Set-Content -Path $RootClaude -Encoding utf8NoBOM
    Write-Host "  [ok]   CLAUDE.md written"
}

Write-Host ""

# ---- 3. Configure .claude\ -----------------------------------

Write-Host "--- 3. Claude Code settings ---"
Write-Host ""

& pwsh "$ScriptDir\setup-claude.ps1"

# ---- Done ----------------------------------------------------

Write-Host ""
Write-Host "=== Done ==="
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Configure AWS SSO profiles for the accounts you have access to:"
Write-Host "     aws configure sso --profile heediq-dev     # most developers"
Write-Host "     aws configure sso --profile heediq-shared  # infra owners only"
Write-Host "     aws configure sso --profile heediq-staging # infra owners only"
Write-Host "     aws configure sso --profile heediq-prod    # infra owners only"
Write-Host "     (Use the IAM Identity Center start URL from the management account console.)"
Write-Host ""
Write-Host "  2. Start Claude from the workspace root:"
Write-Host "     cd '$WorkspaceRoot'; claude"
Write-Host ""
Write-Host "  Note: heediq-infra/scripts/setup.sh is an owner-only one-time operation"
Write-Host "  (CDK bootstrap + OIDC roles). Do NOT run it unless setting up a fresh AWS org."
Write-Host ""

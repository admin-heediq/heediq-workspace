#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =============================================================
# Heediq — Claude Workspace Setup (Windows PowerShell)
#
# Run this AFTER clone-repos.ps1, from the workspace root:
#   pwsh claude-workspace\scripts\setup-workspace.ps1
#
# What it does:
#   1. Writes the workspace-root CLAUDE.md
#   2. Configures .claude\ settings (team + personal)
#   3. Checks GitHub CLI authentication
#
# Prerequisite: clone-repos.ps1 already run (all repos present)
# =============================================================

$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

Write-Host ""
Write-Host "=== Heediq Workspace Setup ==="
Write-Host "Workspace: $WorkspaceRoot"
Write-Host ""

# ---- 1. Write workspace-root CLAUDE.md -----------------------

Write-Host "--- 1. Workspace root CLAUDE.md ---"
Write-Host ""

$RootClaude = Join-Path $WorkspaceRoot "CLAUDE.md"
if (Test-Path $RootClaude) {
    Write-Host "  [skip] CLAUDE.md already exists"
} else {
    $Content = @"
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
    $Content | Set-Content -Path $RootClaude -Encoding utf8NoBOM
    Write-Host "  [ok]   CLAUDE.md written"
}

Write-Host ""

# ---- 2. Configure .claude\ -----------------------------------

Write-Host "--- 2. Claude Code settings ---"
Write-Host ""

& pwsh "$ScriptDir\setup-claude.ps1"

Write-Host ""

# ---- 3. Check GitHub CLI auth --------------------------------

Write-Host "--- 3. GitHub CLI ---"
Write-Host ""

$null = gh auth status 2>&1
if ($LASTEXITCODE -eq 0) {
    $GhUser = gh api user --jq .login 2>$null
    Write-Host "  [ok]   gh CLI authenticated as $GhUser"
} else {
    Write-Host "  [!]  gh CLI not authenticated — needed for PR workflow."
    Write-Host "       Run: gh auth login"
    Write-Host "       Then re-run this script or continue manually."
}

# ---- Done ----------------------------------------------------

Write-Host ""
Write-Host "=== Done ==="
Write-Host ""
Write-Host "Open Claude Code VS Code extension pointed at workspace root:"
Write-Host "  $WorkspaceRoot"
Write-Host ""

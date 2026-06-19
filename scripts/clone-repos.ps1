#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =============================================================
# Heediq — Clone Repos (Windows PowerShell)
#
# Run from the workspace root AFTER cloning claude-workspace:
#
#   mkdir ~/dev/heediq; cd ~/dev/heediq
#   git clone git@github.com:heediq/claude-workspace.git
#   pwsh claude-workspace\scripts\clone-repos.ps1
#
# Options:
#   -Https    Use HTTPS instead of SSH for cloning
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

Write-Host ""
Write-Host "=== Heediq — Clone Repos ==="
Write-Host "Workspace: $WorkspaceRoot"
Write-Host ""

# ---- 1. SSH check (skip if using HTTPS) ----------------------

if (-not $Https) {
    Write-Host "--- 1. GitHub SSH ---"
    Write-Host ""

    $SshConfigPath = Join-Path $env:USERPROFILE ".ssh\config"
    $HasAlias = $false
    if (Test-Path $SshConfigPath) {
        $HasAlias = (Get-Content $SshConfigPath) -match '^\s*Host\s+github-heediq'
    }

    if ($HasAlias) {
        $SshHost = "github-heediq"
        Write-Host "  Using SSH alias 'github-heediq' from ~/.ssh/config"
    } else {
        $SshHost = "github.com"
    }

    $SshResult = ssh -T "git@$SshHost" 2>&1
    if ($SshResult -match "successfully authenticated") {
        Write-Host "  [ok]   SSH authenticated with GitHub"
    } else {
        Write-Host "  [!]  GitHub SSH authentication failed."
        Write-Host ""
        Write-Host "  Set up your SSH key:"
        Write-Host "    1. Generate:  ssh-keygen -t ed25519 -C 'your@email.com'"
        Write-Host "    2. Copy key:  Get-Content ~/.ssh/id_ed25519.pub | clip"
        Write-Host "    3. Add to GitHub: https://github.com/settings/keys"
        Write-Host "    4. Test:      ssh -T git@github.com"
        Write-Host ""
        Write-Host "  Once SSH is working, re-run this script."
        exit 1
    }

    Write-Host ""
    $BaseUrl = "git@${SshHost}:$GithubOrg"
} else {
    Write-Host "  [info] Using HTTPS cloning (-Https flag)"
    $BaseUrl = "https://github.com/$GithubOrg"
}

# ---- 2. Clone repos ------------------------------------------

Write-Host "--- 2. Cloning repos ---"
Write-Host ""

foreach ($Repo in $Repos) {
    $Dest = Join-Path $WorkspaceRoot $Repo
    if (Test-Path (Join-Path $Dest ".git")) {
        Write-Host "  [skip] $Repo — already cloned"
    } else {
        Write-Host "  cloning $Repo ..."
        $null = git clone "$BaseUrl/$Repo.git" $Dest 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [ok]   $Repo"
        } else {
            Write-Host "  [skip] $Repo — not on remote yet (will be scaffolded later)"
        }
    }
}

# ---- Done ----------------------------------------------------

Write-Host ""
Write-Host "=== Done ==="
Write-Host ""
Write-Host "Next: set up the Claude workspace:"
Write-Host "  pwsh claude-workspace\scripts\setup-workspace.ps1"
Write-Host ""

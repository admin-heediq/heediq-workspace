#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve paths
$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$ClaudeDir     = Join-Path $WorkspaceRoot '.claude'
$Tpl           = Join-Path $ScriptDir 'settings.json.tpl'

# Use forward slashes in JSON paths (Claude Code accepts them on Windows)
$WorkspaceRootFwd = $WorkspaceRoot.Replace('\', '/')

Write-Host "Workspace root : $WorkspaceRoot"
Write-Host "Claude config  : $ClaudeDir"
Write-Host ""

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

# Write team settings.json — always overwrite (canonical, sourced from repo)
$settingsJson = (Get-Content $Tpl -Raw) -replace '__WORKSPACE_ROOT__', $WorkspaceRootFwd
$settingsJson | Set-Content -Path (Join-Path $ClaudeDir 'settings.json') -Encoding utf8NoBOM
Write-Host "[ok] $(Join-Path $ClaudeDir 'settings.json') written"

# Write settings.local.json only if it does not exist (personal, not committed)
$localPath = Join-Path $ClaudeDir 'settings.local.json'
if (-not (Test-Path $localPath)) {
    $sshPath = "$($env:USERPROFILE.Replace('\', '/'))/.ssh/**"
    $localJson = @"
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
      "Read($sshPath)"
    ]
  }
}
"@
    $localJson | Set-Content -Path $localPath -Encoding utf8NoBOM
    Write-Host "[ok] $localPath created"
} else {
    Write-Host "[skip] $localPath already exists — not overwritten"
}

Write-Host ""
Write-Host "Done. Always launch Claude from the workspace root:"
Write-Host "  cd '$WorkspaceRoot'; claude"

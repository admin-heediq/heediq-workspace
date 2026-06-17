# heediq-workspace

Shared Claude Code rules, memory, and workspace configuration for the Heediq monorepo.
All repos in the workspace inherit these rules automatically when Claude is launched from the
workspace root.

## First-time setup

Clone this repo as a sibling of the other Heediq repos, so the parent directory becomes your
workspace root (e.g. `~/dev/heediq/heediq-workspace/`). Then run the setup script once — it
creates the Claude Code configuration in the workspace root directory.

**macOS / Linux**

```bash
bash heediq-workspace/scripts/setup-claude.sh
```

**Windows (PowerShell)**

```powershell
pwsh heediq-workspace\scripts\setup-claude.ps1
```

The script:
- Writes `<workspace-root>/.claude/settings.json` — team settings (always from the repo template).
- Creates `<workspace-root>/.claude/settings.local.json` — personal settings (only if it doesn't
  exist yet, so re-running is safe).

Re-run whenever you pull updates to `scripts/settings.json.tpl` to pick up changes to team settings.

## Launching Claude

Always start Claude from the **workspace root** (the directory that contains `heediq-workspace/`),
not from inside a sub-repo:

```bash
cd ~/dev/heediq   # adjust to your path
claude
```

Starting from a sub-repo skips the workspace `CLAUDE.md` and the shared rules won't load.

## What the setup configures

| Setting | Where | What it does |
|---------|-------|-------------|
| `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` | `settings.json` | Prevents expansion to the 1M token context window |
| `UserPromptSubmit` hook | `settings.json` | Reminds Claude to read `heediq-workspace/CLAUDE.md` on every prompt |
| `autoCompactEnabled: true` | `settings.local.json` | Auto-compacts context before it fills |
| `permissions.allow` | `settings.local.json` | Pre-approves common git/SSH commands |

## Repository layout

```
heediq-workspace/
  CLAUDE.md                     ← root rules + imports (Claude reads this first)
  rules/
    01-development-workflow.md  ← Step 0–6 sequence for every change
    02-git-and-commits.md       ← branching, commits, PRs
    03-ui-kit.md                ← UI component library rules
    04-loading-and-feedback.md  ← loading & feedback standards
    05-testing.md               ← test layers & pre-PR gate
    06-documentation.md         ← code-level READMEs (no Confluence)
    07-engineering-standards.md ← types, security, errors, cost, a11y, perf
    08-memory.md                ← memory contract & coherence check
    09-decisions.md             ← decision capture & business memory
  memory/
    business/
      DECISIONS.md              ← canonical decisions log (source of truth)
    codebase/
      MEMORY.md                 ← codebase index
      feature_dependency_map.md ← upstream/downstream dependency map
  plans/
    wip-*.md                    ← one WIP file per in-flight branch
  scripts/
    setup-claude.sh             ← Claude Code config setup (macOS/Linux)
    setup-claude.ps1            ← Claude Code config setup (Windows PowerShell)
    setup-aws-oidc.sh           ← GitHub Actions OIDC roles setup (all platforms — see note)
    settings.json.tpl           ← team settings template (path-substituted by scripts)
```

## AWS setup scripts

`setup-aws-oidc.sh` creates the GitHub Actions OIDC providers and IAM roles across all four AWS
accounts in one idempotent run. Run it once after provisioning accounts, or again after a disaster
recovery re-account.

**macOS / Linux**

```bash
bash heediq-workspace/scripts/setup-aws-oidc.sh
```

**Windows — use Git Bash** (ships with Git for Windows, not PowerShell)

```bash
# Open Git Bash, then:
bash heediq-workspace/scripts/setup-aws-oidc.sh
```

A native PowerShell port does not exist — inline JSON heredocs are too verbose in PowerShell for
no practical gain, since Git Bash covers all Windows developer setups. If you're using WSL, note
that AWS CLI profiles must be configured separately inside the WSL environment.

Make sure SSO sessions are active in all profiles before running:

```bash
aws sso login --profile heediq-shared
aws sso login --profile heediq-dev
aws sso login --profile heediq-staging
aws sso login --profile heediq-prod
```

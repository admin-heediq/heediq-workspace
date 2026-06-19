# claude-workspace

Shared Claude Code rules, memory, and workspace configuration for the Heediq dev environment.
All repos in the workspace inherit these rules automatically when Claude is launched from the
workspace root.

---

## New machine setup

Three commands to go from a blank machine to a working Heediq workspace:

```bash
# 1. Create workspace directory and clone claude-workspace into it
mkdir ~/dev/heediq && cd ~/dev/heediq
git clone git@github.com:heediq/claude-workspace.git   # adjust path as needed

# 2. Run the machine setup script — clones all repos, writes CLAUDE.md, configures .claude/
bash claude-workspace/scripts/setup-machine.sh

# 3. Start Claude from the workspace root
cd ~/dev/heediq && claude
```

**Windows (PowerShell):**

```powershell
mkdir ~/dev/heediq; cd ~/dev/heediq
git clone git@github.com:heediq/claude-workspace.git
pwsh claude-workspace\scripts\setup-machine.ps1
cd ~/dev/heediq; claude
```

The setup script:
- Clones all Heediq repos that exist on GitHub (skips ones not yet scaffolded)
- Writes the workspace-root `CLAUDE.md` that loads these rules into Claude
- Configures `.claude/settings.json` (team) and `.claude/settings.local.json` (personal)

### SSH alias (optional)

If you manage multiple GitHub accounts and need a separate SSH key for the `heediq` org,
add this to `~/.ssh/config` before running setup:

```
Host github-heediq
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_heediq   # your heediq-org SSH key
```

The setup script detects the alias automatically and uses it for cloning. Without it, standard
`git@github.com` is used. Pass `--https` to either script to use HTTPS instead.

### Prerequisites

Install before running setup:

| Tool | Version | Install |
|------|---------|---------|
| git | latest | system package manager or https://git-scm.com |
| Node.js | 22 LTS | https://nodejs.org |
| pnpm | latest | `npm install -g pnpm` |
| AWS CLI | v2 | https://aws.amazon.com/cli/ |
| GitHub CLI | latest | https://cli.github.com/ |
| Claude Code | latest | `npm install -g @anthropic-ai/claude-code` |

---

## After setup — AWS configuration

Configure AWS SSO profiles (required for infra work):

```bash
# One-time SSO configuration per profile
aws configure sso --profile heediq-shared   # shared-services account
aws configure sso --profile heediq-dev
aws configure sso --profile heediq-staging
aws configure sso --profile heediq-prod

# Login before each session where you need AWS access
aws sso login --profile heediq-shared
aws sso login --profile heediq-dev
# etc.
```

Use the IAM Identity Center start URL from the management account console.

Then run the one-time AWS infrastructure setup (CDK bootstrap + OIDC roles):

```bash
cd ~/dev/heediq/heediq-infra
bash scripts/setup.sh
```

See `heediq-infra/README.md` for the full initial setup sequence (shared-services deploy, NS records, etc.).

---

## Day-to-day: updating Claude settings

Re-run `setup-claude.sh` whenever `scripts/settings.json.tpl` changes (team settings update):

```bash
bash claude-workspace/scripts/setup-claude.sh    # macOS/Linux
pwsh claude-workspace\scripts\setup-claude.ps1   # Windows
```

This overwrites `settings.json` from the template but never touches your personal `settings.local.json`.

---

## Always launch Claude from the workspace root

```bash
cd ~/dev/heediq   # the directory that contains claude-workspace/
claude
```

Starting from inside a sub-repo skips the workspace `CLAUDE.md` and the shared rules won't load.

---

## Repository layout

```
claude-workspace/
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
      architecture.md           ← AWS stack, environments, transcription pipeline
      product.md                ← product spec, billing, auth, UX decisions
      branding.md               ← logo, tokens, type scale, component states
    codebase/
      MEMORY.md                 ← codebase index (pointers to READMEs)
      feature_dependency_map.md ← upstream/downstream dependency map
  plans/
    wip-*.md                    ← one WIP file per in-flight branch
  scripts/
    setup-machine.sh            ← NEW MACHINE: clone repos + write CLAUDE.md + configure .claude/
    setup-machine.ps1           ← same for Windows PowerShell
    setup-claude.sh             ← configure .claude/ only (re-run to pick up settings changes)
    setup-claude.ps1            ← same for Windows PowerShell
    settings.json.tpl           ← team settings template (substituted by setup scripts)
```

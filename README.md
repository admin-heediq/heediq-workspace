# claude-workspace

Shared Claude Code rules, memory, and workspace configuration for the Heediq dev environment.
All repos in the workspace inherit these rules automatically when Claude is launched from the
workspace root.

---

## New machine setup

### Prerequisites

Install before running setup:

| Tool | Version | Install |
|------|---------|---------|
| git | latest | system package manager or https://git-scm.com |
| Node.js | 22 LTS | https://nodejs.org |
| pnpm | latest | `npm install -g pnpm` |
| GitHub CLI (`gh`) | latest | https://cli.github.com/ |
| Claude Code | latest | `npm install -g @anthropic-ai/claude-code` |

SSH for GitHub is checked automatically in step 2 — the script guides you if it's not set up.

### macOS / Linux

```bash
# 1. Create workspace directory and clone claude-workspace into it
mkdir ~/dev/heediq && cd ~/dev/heediq
git clone git@github.com:heediq/claude-workspace.git

# 2. Clone all repos (checks SSH, guides setup if missing)
bash claude-workspace/scripts/clone-repos.sh

# 3. Set up the Claude workspace (writes CLAUDE.md, configures .claude/)
bash claude-workspace/scripts/setup-workspace.sh

# 4. Start Claude from the workspace root
cd ~/dev/heediq && claude
```

### Windows (PowerShell)

```powershell
mkdir ~/dev/heediq; cd ~/dev/heediq
git clone git@github.com:heediq/claude-workspace.git
pwsh claude-workspace\scripts\clone-repos.ps1
pwsh claude-workspace\scripts\setup-workspace.ps1
cd ~/dev/heediq; claude
```

### SSH alias (optional — multiple GitHub accounts)

If you use a separate SSH key for the `heediq` org (e.g. you have a personal GitHub account too),
add this to `~/.ssh/config` **before** running `clone-repos.sh`:

```
Host github-heediq
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_heediq
```

`clone-repos.sh` detects the alias automatically and uses it for all clones. Without it, standard
`git@github.com` is used. Pass `--https` / `-Https` to use HTTPS instead.

---

## Day-to-day: updating Claude settings

Re-run `setup-claude.sh` whenever `scripts/settings.json.tpl` changes:

```bash
bash claude-workspace/scripts/setup-claude.sh    # macOS/Linux
pwsh claude-workspace\scripts\setup-claude.ps1   # Windows
```

This overwrites `settings.json` from the template but never touches your personal
`settings.local.json`.

---

## Always launch Claude from the workspace root

```bash
cd ~/dev/heediq   # the directory that contains claude-workspace/
claude
```

Starting from inside a sub-repo skips the workspace `CLAUDE.md` and the shared rules won't load.

---

## AWS access

Regular developers **do not need AWS CLI configured** — local development uses DynamoDB Local /
LocalStack (D-030), and all cloud deployments go through CI via OIDC (no stored credentials).

If you need to inspect deployed resources (CloudWatch logs, etc.), ask Andrii for an IAM Identity
Center permission set for `heediq-dev`, then run:

```bash
aws configure sso --profile heediq-dev
aws sso login --profile heediq-dev
```

Infrastructure provisioning (CDK bootstrap, OIDC roles, SSO profiles for all accounts) is
owner-only and documented in `heediq-infra/README.md`.

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
    clone-repos.sh              ← SSH check + clone all repos into workspace root
    clone-repos.ps1             ← Windows
    setup-workspace.sh          ← write CLAUDE.md + configure .claude/ settings
    setup-workspace.ps1         ← Windows
    setup-claude.sh             ← configure .claude/ only (re-run to pick up settings changes)
    setup-claude.ps1            ← Windows
    settings.json.tpl           ← team settings template (substituted by setup scripts)
```

# Periodic Consistency Check

Run this check at the start of a new feature, after a multi-repo release, or when memory/docs feel stale. It catches drift between READMEs, memory, and actual code before it causes real bugs. Andrii triggers it by asking for a "consistency check" or "coherency check".

This extends the per-session coherence check in `08-memory.md` (which covers only business memory files) to cover the full cross-repo surface: code, READMEs, memory indexes, and disaster recovery docs.

---

## When to run

- Before starting a multi-repo feature that touches shared contracts
- After merging a release that changed env vars, SSM paths, or SQS message schemas
- When something "felt off" in a recent session — stale gotcha, wrong path, silent failure
- On request ("run a consistency check")
- Periodically: ask Andrii at session end whether to schedule one

Claude must ask at the end of every session that involved cross-repo changes: *"Want me to run the full consistency check next session to verify everything is in sync?"*

---

## Scope — what to check

### 1. Business memory coherence (from `08-memory.md`)
Run the four-point coherence check from `rules/08-memory.md` first. It must be clean before proceeding to the broader check.

### 2. Per-repo README vs code

For every repo (`heediq-infra`, `heediq-api`, `heediq-shared`, `heediq-web`, `heediq-worker-transcription`, `heediq-worker-summarization`):

| What to verify | How |
|---|---|
| README exists at repo root | `ls README.md` |
| Key files listed in README exist at stated paths | Check each path |
| Env var names in README match actual code (`config.ts` / `config.py`) | Grep config file; compare |
| SSM/Secrets Manager paths in README match CDK stack code | Grep stack files; compare |
| SQS message schema fields in README match `@heediq/shared` `messages.ts` and Python `models.py` | Read both; compare |
| Test count / test commands in README match `package.json` / `pyproject.toml` | Grep |
| DynamoDB table names, GSIs, and key design in README match `foundation-stack.ts` | Read stack; compare |
| Account IDs, domain names, and ARNs in README match `lib/config.ts` | Compare |
| Stale "TODO" or "until PR #N merges" gotchas | Grep for "until", "file:", "to be added after", "PR #" |

### 3. Cross-repo contract consistency

Check contracts that span repos — a mismatch here causes silent runtime failures:

| Contract | Canonical source | Consumers to check |
|---|---|---|
| `SummarizationJobMessage` schema | `heediq-shared/src/messages.ts` | `heediq-worker-transcription/src/models.py`, `heediq-worker-summarization/src/handler.ts` |
| `TranscriptionJobMessage` schema | `heediq-shared/src/messages.ts` | `heediq-worker-transcription/src/models.py` (hand-maintained) |
| Lambda env var names | CDK stack `environment:{}` blocks | Lambda runtime `config.ts` / `config.py` `requireEnv()` calls |
| SSM parameter paths | CDK stack `ssm.StringParameter` writes | Consuming Lambda `config.ts` reads + README docs |
| Secrets Manager paths | CDK IAM grants (`/heediq/…/*`) + README runbook | Lambda `config.ts` `CLAUDE_SECRET_NAME` + README runbook |
| Claude model IDs | `handler.ts` `MODELS` map | `rules/07-engineering-standards.md` cost section, `DECISIONS.md` D-067 |
| Tier values (`free`/`paid`) | `heediq-shared/src/enums.ts` `TierSchema` | All message producers (API, transcription worker) and consumers (summarization worker) |

### 4. Memory index accuracy

- `memory/codebase/MEMORY.md`: every decision ID listed for a module actually exists in `DECISIONS.md` as Locked (not Superseded)
- `memory/codebase/MEMORY.md`: every README path pointed to actually exists on disk
- `memory/codebase/feature_dependency_map.md`: upstream/downstream entries reflect current code (no removed deps, no new deps missing)

### 5. Local dev setup completeness

For each repo, verify the README covers:
- How to install dependencies (`pnpm install` / `pip install`)
- Required env vars for running locally (list them; note which require real AWS vs can be faked)
- How to run tests (`pnpm run test:pre-pr` / `pytest -q`)
- How to start the service locally if applicable
- `NODE_AUTH_TOKEN` / GitHub PAT requirement if the repo consumes `@heediq/shared`

### 6. Disaster recovery / initial setup completeness

For each repo, verify the README (or the infra README) covers:
- What must exist before the first deploy (SSM params, secrets, CDK bootstrap)
- How to trigger a fresh deploy from scratch (CI command or manual CDK command)
- How to recover if the Lambda/service needs rollback

The canonical DR doc is `heediq-infra/README.md` §"Initial Setup" and §"Setting up a new environment from scratch". Individual service READMEs should cross-reference it and add their specific prerequisites.

---

## How to run

1. Run the `08-memory.md` coherence check first. Fix any issues before continuing.
2. For broad audits spanning all repos, spawn parallel agents — one per pair of repos — to read and compare without blowing the main context window. Each agent should return a structured PASS/FAIL/MISSING table.
3. Synthesize findings. Fix critical and high-severity issues immediately (operational bugs, wrong secret paths, stale env var names). Flag medium/low for Andrii to prioritize.
4. Commit all README and memory fixes separately per repo with `docs:` or `docs(memory):` prefix.
5. After fixes are committed, push each affected repo's branch (or ask Andrii if mid-session).

### Severity tiers for findings

| Tier | Definition | Action |
|---|---|---|
| **Critical** | Would cause a production Lambda cold-start failure or wrong secret path in a runbook | Fix immediately before any other work |
| **High** | Wrong contract claim, stale env var name, wrong test count — causes confusion or silent failure | Fix in same session |
| **Medium** | Missing local dev section, missing DR section, aspirational language not flagged as future | Fix or ticket before next release |
| **Low** | Wrong version number in README prose, minor cosmetic inaccuracy | Fix opportunistically |

---

## Output format

After running, report findings as a table:

```
| # | Severity | Repo | File | Finding | Fixed? |
|---|---|---|---|---|---|
| 1 | Critical | heediq-infra | README.md:361 | Secret path says claude-api-key, code says anthropic-api-key | Yes |
| 2 | High | heediq-api | README.md:65 | Test count says 16, actual is 17 | Yes |
...
```

Then summarize: N findings, N fixed this session, N deferred. List anything deferred with a reason.

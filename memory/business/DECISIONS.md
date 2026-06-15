# Heediq Decisions Log (DECISIONS.md)

Canonical, append-only record of locked decisions — the business-memory source of truth. Capture and
format per `rules/09-decisions.md`. Read this at the start of every chat; locked decisions are
constraints.

> **Migration note:** the prior `heediq-decisions.md` artifact is the original home of decisions made
> before this repo existed. Its full, exact text (including verbatim values like logo SVG coordinates
> and precise cost figures) should be **migrated here verbatim** — do not reconstruct exact specs from
> memory. The imported entries below are concise index stubs until that paste happens; treat the
> original artifact as authoritative for any detail.

---

## Imported (locked before this repo — verify detail against the original `heediq-decisions.md`)

### D-001 · Full AWS serverless stack — Locked
**Area:** Architecture · **Decision:** Build on a full AWS serverless stack (Lambda, Fargate, SQS,
DynamoDB). **Why:** scalability + cost at Heediq's profile. *(Migrate full text.)*

### D-002 · AWS CDK + GitHub Actions CI/CD — Locked
**Area:** Infra · **Decision:** IaC via AWS CDK; CI/CD via GitHub Actions.

### D-003 · Three AWS accounts + shared ECR — Locked
**Area:** Infra · **Decision:** Separate prod/staging/dev accounts under one AWS Organization; a single
shared ECR registry — build the image once, promote across environments.

### D-004 · Self-hosted faster-whisper on Fargate Spot — Locked
**Area:** Infra / Cost · **Decision:** Transcription runs on self-hosted `faster-whisper` on AWS
Fargate Spot via SQS. AWS Transcribe dropped entirely. **Why:** dramatically cheaper at scale.

### D-005 · Transcription tiers — Locked
**Area:** Cost · **Decision:** Free tier = whisper `small` on CPU (~2¢/60-min meeting); paid tier =
whisper `large-v3` + pyannote diarization with chunked parallel processing (~12¢/60-min meeting).

### D-006 · Cost optimizations — Locked
**Area:** Cost · **Decision:** Silence trimming (10–30% duration reduction) accepted as safe; 2× audio
speed-up rejected (degrades accuracy).

### D-007 · DynamoDB-only at launch — Locked
**Area:** Architecture · **Decision:** DynamoDB only at launch; Aurora Serverless v2 deferred (possible
future migration).

### D-008 · Design system tokens — Locked
**Area:** Design · **Decision:** Charcoal/amber color tokens; Inter/Geist for UI; JetBrains Mono for
transcripts; three-state Listen button (idle/recording/processing); brand name styled lowercase as
"heediq" in UI. *(Migrate exact token values.)*

### D-009 · Brand & logo — Locked
**Area:** Brand · **Decision:** Logo = four angled amber slabs (exact SVG spec in original doc); name
layers "heed" + "HQ" + "IQ"; full asset library generated. Domain: heediq.com. *(Migrate verbatim SVG.)*

### D-010 · MVP build order — Locked
**Area:** Product · **Decision:** auth/onboarding → home/Listen → recordings library → recording
detail/summary (critical path: record → transcribe → summarize → view). Org/billing and calendar/
meeting-bot settings are follow-on.

### D-011 · Pricing principle — Locked
**Area:** Pricing · **Decision:** Flat per-seat pricing without usage caps doesn't work at Heediq's
transcription cost structure; a fair-use meeting-cap model is preferred. *(Exact packaging TBD.)*

---

## New (this repo / workspace)

### D-012 · Workspace rules & memory repo — Locked (2026-06-15)
**Area:** Process · **Decision:** Adopt `heediq-workspace` as the canonical repo for Claude's rules,
memory, and plans, hosted at github.com/admin-heediq/heediq-workspace. Root `CLAUDE.md` imports the
modular rule set; memory is split into business + codebase tracks.
**Why:** one shared, version-controlled contract and memory for the team.

### D-013 · GitHub as git host & CI — Locked (2026-06-15)
**Area:** Infra · **Decision:** Heediq is on GitHub; PRs via `gh`; CI via GitHub Actions.
**Supersedes:** — (consistent with D-002).

### D-014 · No Jira for now — Locked (2026-06-15)
**Area:** Process · **Decision:** No issue tracker (Jira) for Heediq dev tracking currently; may adopt
later. Branches/commits use `<type>/<short-kebab-desc>` with no issue key required.

### D-015 · Two-track memory + auto-decision-capture — Locked (2026-06-15)
**Area:** Process · **Decision:** Maintain business memory (decisions, this file) alongside codebase
memory; decisions are captured automatically and immediately when locked, per `rules/09-decisions.md`.

### D-016 · Documentation via code-level READMEs — Locked (2026-06-15)
**Area:** Process · **Decision:** Project documentation lives in `README.md` files next to the code
(replacing Confluence BD/TDD/TP/TRM). See `rules/06-documentation.md`.

---

## Open / proposed (not yet locked)
- **`develop` integration-branch model** — proposed in `rules/02-git-and-commits.md`; confirm or use
  `main` + feature branches while solo.
- **UI base = Tailwind + Radix + shadcn/ui-style local kit** — proposed in `rules/03-ui-kit.md`.
- **Test stack = Vitest/RTL + DynamoDB Local/LocalStack + Playwright + k6** — proposed in
  `rules/05-testing.md`.

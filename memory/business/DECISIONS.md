# Heediq Decisions Log (DECISIONS.md)

Canonical, append-only record of locked decisions — the business-memory source of truth. Capture and
format per `rules/09-decisions.md`. Read this at the start of every chat; locked decisions are
constraints.

> **Migration complete (2026-06-16):** the entries below were migrated from the original chat
> history verbatim (not reconstructed from a memory summary). Detailed text — SVG coordinates,
> exact cost figures, full brand story, etc. — now lives in `branding.md`, `product.md`, and
> `architecture.md` in this folder; entries here stay lean and link out per `rules/09-decisions.md`.
> Worth a quick skim against the source before treating these as final, since they were assembled
> from several past conversations rather than confirmed fresh in this one.

---

## Architecture & Infrastructure

### D-001 · Full AWS serverless stack — Locked (2026-06-11)
**Area:** Architecture
**Decision:** Build on a full AWS serverless stack: Lambda, API Gateway, Fargate Spot, DynamoDB,
S3, SQS, EventBridge, Cognito, CloudFront, Route 53, Secrets Manager, CloudWatch.
**Why:** scalability + cost profile fits Heediq's usage-spiky, mostly-async workload.
**Related:** `memory/business/architecture.md`

### D-002 · AWS CDK + GitHub Actions CI/CD — Locked (2026-06-11)
**Area:** Infra
**Decision:** IaC via AWS CDK; CI/CD via GitHub Actions.
**Related:** `memory/business/architecture.md`

### D-003 · Three AWS accounts + shared ECR — Locked (2026-06-11)
**Area:** Infra
**Decision:** Separate prod/staging/dev accounts under one AWS Organization; a single shared ECR
registry — build the image once, promote across environments. Branch-based deployment with a
manual approval gate before production.
**Related:** `memory/business/architecture.md`
**Superseded by:** D-036

### D-004 · Self-hosted faster-whisper on Fargate Spot — Locked (2026-06-11)
**Area:** Infra / Cost
**Decision:** Transcription runs on self-hosted `faster-whisper` on AWS Fargate Spot via SQS.
AWS Transcribe dropped entirely.
**Why:** ~70–75× cheaper than AWS Transcribe at scale (~$6/mo vs ~$432/mo at 10 meetings/day);
makes a usage-inclusive pricing model viable at all.
**Related:** `memory/business/architecture.md`

### D-005 · Transcription tiers — Locked (2026-06-11)
**Area:** Cost
**Decision:** Free tier = whisper `small` on CPU (~$0.02/60-min meeting, capped 30–45 min/recording);
paid tier = whisper `large-v3` + pyannote diarization with chunked parallel processing
(~$0.12/60-min meeting).
**Related:** `memory/business/architecture.md`

### D-006 · Transcription cost optimizations — Locked (2026-06-11)
**Area:** Cost
**Decision:** Silence trimming accepted (10–30% duration reduction, safe). 2× audio speed-up
rejected (degrades word-error-rate and diarization accuracy too much).
**Related:** `memory/business/architecture.md`

### D-007 · DynamoDB-only at launch — Locked (2026-06-11)
**Area:** Architecture
**Decision:** DynamoDB only at launch; Aurora Serverless v2 deferred (possible future migration
for relational queries).
**Why:** Aurora's ~$45/mo fixed floor dominates the bill disproportionately at early scale.
**Related:** `memory/business/architecture.md`

### D-021 · Multi-tenancy — shared DB, row-level isolation — Locked (2026-06-11)
**Area:** Architecture
**Decision:** Single shared database, row-level tenant isolation via `org_id` on every
tenant-scoped row. Query pattern: `WHERE org_id = :tenant AND (owner_user_id = :user OR :role =
'admin')`.
**Related:** `memory/business/architecture.md`

### D-022 · Data retention & audio lifecycle — Locked (2026-06-11)
**Area:** Policy
**Decision:** Free tier — audio + transcript stored 30 days, then audio deleted, transcript kept
indefinitely. Paid tier — audio stored 90 days then moved to S3 Glacier Deep Archive, transcript
indefinite. On cancellation: 30-day grace period, then full org data deletion.
**Why:** transcript text is the actual product value (cheap to retain); audio is the
expensive/bulky asset and is tiered down or archived.
**Related:** `memory/business/product.md`

### D-023 · Upload & transcription processing flow — Locked (2026-06-11)
**Area:** Architecture
**Decision:** Client uploads directly to S3 via a presigned URL. An S3 event feeds an SQS queue;
EventBridge Pipes triggers an ECS Fargate Spot `RunTask` (faster-whisper, per D-004) with zero
idle cost. Job status is written to DynamoDB; client polls for completion.
**Supersedes:** an earlier S3-event → Lambda → AWS-Transcribe-job orchestration (dropped
alongside D-004).
**Related:** `memory/business/architecture.md`

---

## Brand & Design

### D-008 · Design system tokens — Locked (2026-06-11)
**Area:** Design
**Decision:** Charcoal/amber color token scale; Inter/Geist for UI (400/500 weights only);
JetBrains Mono for transcripts; 4px-base spacing scale + sm/md/lg/full radius tokens; three-state
Listen button (idle/recording/processing); inline-hint + dedicated empty states. Brand name
styled lowercase as "heediq" in UI.
**Related:** `memory/business/branding.md` (exact hex values, type scale, spacing scale, button
states, empty-state copy)

### D-009 · Brand & logo — Locked (2026-06-11)
**Area:** Brand
**Decision:** Logo = four angled (−12°) amber slabs forming an h+q monogram (exact SVG in
`branding.md` — reproduce verbatim, do not redesign). Name layers "heed" + "HQ" + "IQ"; the four
slabs also visually represent "HQ". Domain: heediq.com. Full asset library generated
(`heediq-brand-assets.zip`).
**Related:** `memory/business/branding.md` (verbatim SVG, brand story, taglines, asset list)

### D-026 · Home / Listen screen UX — Locked (2026-06-11)
**Area:** Design
**Decision:** Home screen centers on one large "Listen" button (Shazam-style primary CTA) for
live recording. Secondary actions: upload an audio file, upload a text file (skips transcription,
straight to summary), view recordings. A subtle usage/limit indicator sits in the top bar. The
recordings library is a separate nav page, not embedded in home.
**Why:** one obvious primary action keeps the entry point simple; secondary paths cover
non-live-recording use cases without competing for attention.
**Related:** `memory/business/product.md`, `memory/business/branding.md` (button states)

---

## Product, Access & Billing

### D-017 · Account & roles model — Locked (2026-06-11)
**Area:** Product
**Decision:** Org-first account model for all users; personal users = single-seat org
(owner/admin), no separate personal account type. Roles: Admin (billing, seats, member
management, sees all org content) and Member (own content only). No per-recording sharing at
launch (deferred).
**Why:** keeps the data model unified across personal and team accounts.
**Related:** `memory/business/product.md`

### D-018 · Free-tier usage limits — Locked (2026-06-11)
**Area:** Pricing
**Decision:** Free tier is a per-org shared usage pool with a one-way usage-decay ratchet: 1
use/day → after 3 lifetime uses, 2 uses/week → after 6 lifetime uses, 1 use/week (cumulative
lifetime count, never resets). One "use" = one transcription summarized and delivered. Exceeding
the limit triggers a soft upgrade prompt, never a hard block. Single paid plan exists alongside
free at launch.
**Why:** lets free users get real value while creating natural upgrade pressure without a
punitive cutoff.
**Related:** `memory/business/product.md`

### D-019 · Billing — Stripe, org as customer — Locked (2026-06-11)
**Area:** Pricing
**Decision:** Stripe is the billing provider. Customer = org (not individual user); per-seat
quantity-based subscription. No card required on signup/trial; Stripe Checkout triggers only on
upgrade. Subscription state synced via Stripe webhooks.
**Related:** `memory/business/product.md`

### D-011 · Pricing principle — Locked (2026-06-11)
**Area:** Pricing
**Decision:** Flat per-seat pricing without usage caps or overage billing doesn't work at
Heediq's transcription cost structure; a fair-use meeting-cap model is preferred.
**Why:** confirmed via gross-margin math against AWS Transcribe baseline costs.
**Note:** the original supporting number ($35–40/seat/mo) predates the faster-whisper cost pivot
(D-004/D-005, ~70–75× cheaper) and should be revisited — exact packaging is still open. See
`memory/business/product.md`.

### D-020 · Auth — AWS Cognito + federated IdPs — Locked (2026-06-11)
**Area:** Architecture
**Decision:** Authentication via AWS Cognito User Pool: email/password plus Google and Microsoft
(Entra/Azure AD) as federated identity providers, all from day one. SAML/OIDC for enterprise IdPs
explicitly deferred to later (design auth so it's addable, don't build it now). Email-domain
match on signup surfaces a "request to join" flow requiring admin approval — automatic
domain-based addition is explicitly not implemented (security).
**Related:** `memory/business/product.md`

### D-024 · Platform — mobile-first PWA — Locked (2026-06-11)
**Area:** Product
**Decision:** Heediq ships as a mobile-first, desktop-friendly installable PWA. Offline recording
supported (local capture, queued upload on reconnect; transcripts cached offline). True
lock-screen background recording is not feasible on iOS Safari; mitigated with the Screen Wake
Lock API during recording. Push notifications ("transcript ready") built at launch via Web Push
API (iOS 16.4+ for installed PWAs). Browser baseline: iOS Safari 16.4+, Android Chrome last 2,
desktop Chrome/Edge/Safari/Firefox last 2. Breakpoints: mobile <640px, tablet 640–1024px, desktop
>1024px.
**Why:** one codebase across mobile/desktop without native app-store overhead; explicit
fallback for iOS's background-audio limitation avoids overselling a capability the platform can't
deliver.
**Related:** `memory/business/product.md`

### D-025 · Paid-tier meeting bot — Locked (2026-06-11)
**Area:** Product
**Decision:** Paid tier supports an automated meeting bot via a third-party agent (e.g.
Recall.ai) with calendar OAuth integration, rather than building a custom bot in-house.
**Why:** third-party agents already solve cross-platform call-joining reliably.
**Related:** `memory/business/product.md`

### D-010 · MVP build order — Locked (2026-06-11)
**Area:** Product
**Decision:** auth/onboarding → home/Listen → recordings library → recording detail/summary
(critical path: record → transcribe → summarize → view). Org/billing and calendar/meeting-bot
settings are follow-on.
**Related:** `memory/business/product.md`

---

## Process (this workspace)

### D-012 · Workspace rules & memory repo — Locked (2026-06-15)
**Area:** Process
**Decision:** Adopt `heediq-workspace` as the canonical repo for Claude's rules, memory, and
plans, hosted at github.com/admin-heediq/heediq-workspace. Root `CLAUDE.md` imports the modular
rule set; memory is split into business + codebase tracks.
**Why:** one shared, version-controlled contract and memory for the team.
**Superseded by:** D-046

### D-013 · GitHub as git host & CI — Locked (2026-06-15)
**Area:** Infra
**Decision:** Heediq is on GitHub; PRs via `gh`; CI via GitHub Actions.
**Supersedes:** — (consistent with D-002).

### D-014 · No Jira for now — Locked (2026-06-15)
**Area:** Process
**Decision:** No issue tracker (Jira) for Heediq dev tracking currently; may adopt later.
Branches/commits use `<type>/<short-kebab-desc>` with no issue key required.

### D-015 · Two-track memory + auto-decision-capture — Locked (2026-06-15)
**Area:** Process
**Decision:** Maintain business memory (decisions, this file) alongside codebase memory;
decisions are captured automatically and immediately when locked, per `rules/09-decisions.md`.

### D-016 · Documentation via code-level READMEs — Locked (2026-06-15)
**Area:** Process
**Decision:** Project documentation lives in `README.md` files next to the code (replacing
Confluence BD/TDD/TP/TRM). See `rules/06-documentation.md`.

---

## Infrastructure Access & Naming

### D-036 · 5-account AWS structure + SSO + OIDC (2026-06-16) — Locked
**Area:** Infra
**Decision:** Five AWS accounts under one AWS Organization:
- **Management** — org root, IAM Identity Center (SSO), consolidated billing. No workloads run here.
- **Shared services** — ECR (all container images), and future cross-environment shared infrastructure. OIDC trust for CI image push.
- **Dev / Staging / Prod** — isolated workload accounts (DynamoDB, Lambda, S3, SQS, Cognito, etc. each in their own account).

Human access via IAM Identity Center (SSO): one login URL, permission sets defined centrally (e.g. `AdministratorAccess`, `DeveloperAccess`), users assume roles per account. No IAM users or long-lived access keys.

Machine access (GitHub Actions) via OIDC: a `GitHubActionsDeployRole` IAM role in each account (workload + shared-services) with branch-scoped trust. No stored AWS credentials in GitHub Secrets — only role ARNs in workflow files. Container images are pushed to ECR in the shared-services account and promoted (by image tag) into dev → staging → prod.
**Why:** Account boundary is the blast-radius boundary; SSO eliminates credential sprawl; OIDC eliminates long-lived machine credentials. Shared-services account gives ECR a neutral home and room to grow into a platform layer without polluting workload accounts. Follows AWS Landing Zone best practice.
**Supersedes:** D-003
**Superseded by:** —
**Related code:** `heediq-infra/`

### D-037 · Resource naming — no environment prefix (2026-06-16) — Locked
**Area:** Infra
**Decision:** All AWS resources named `heediq-{entity}` with no environment prefix — e.g. `heediq-recordings`, `heediq-audio-uploads`, `heediq-transcription`. The account boundary is the environment boundary; the same name in different accounts refers to fully isolated resources. CDK stack names follow `Heediq{Service}Stack`. IAM policies use `heediq-*` wildcard to cover all resources in a given account.
**Why:** Environment prefix is redundant and noisy when accounts are isolated. Cleaner names, simpler CDK code, easier IAM policies.
**Supersedes:** — (replaces the `heediq-{env}-{entity}` pattern proposed pre-D-036)
**Superseded by:** —
**Related code:** `heediq-infra/`

### D-038 · SSM + secrets path convention (2026-06-16) — Locked
**Area:** Infra
**Decision:** SSM Parameter Store paths: `/heediq/{service}/{param}` — e.g. `/heediq/api/cognito-user-pool-id`. Secrets Manager paths: `/heediq/{service}/{secret}` — e.g. `/heediq/api/stripe-secret-key`. No environment prefix in either (account-scoped). CDK injects non-secret config (table names, bucket names, Cognito IDs) as Lambda environment variables at deploy time. Actual secrets (Stripe key, Claude API key, Recall.ai key) are fetched from Secrets Manager at Lambda cold start via the AWS Parameters and Secrets Lambda Extension (no SDK call in hot path).
**Why:** Account boundary makes env prefix redundant. Separating config (env vars, fast) from secrets (Secrets Manager, secure) avoids SSM latency on every config value while keeping secrets out of the Lambda console.
**Supersedes:** —
**Superseded by:** —
**Related code:** `heediq-infra/`, `heediq-api/`

---

## Stack & Repos

### D-027 · `develop` integration-branch model (2026-06-16) — Locked
**Area:** Process
**Decision:** `develop` is the integration branch. All feature/fix/chore branches cut from `develop` and merge back via PR. Direct commits to `develop`, `main`, or `master` are not allowed. `heediq-workspace` is exempt — memory/plans commit straight to its default branch.
**Why:** Trunk-based integration with short-lived feature branches; keeps main always releasable.
**Supersedes:** — **Superseded by:** —
**Related code:** `rules/02-git-and-commits.md`

### D-028 · UI component stack (2026-06-16) — Locked
**Area:** Architecture / Design
**Decision:** UI built on Tailwind CSS (styling), Radix UI headless primitives (accessibility/keyboard/ARIA for complex components), and a shadcn/ui-style local component kit (templates copied into-repo and owned, not a black-box dependency).
**Why:** Radix solves accessibility correctly for dialogs, dropdowns, tooltips etc.; Tailwind enforces token-based styling per D-008; shadcn pattern means no vendor lock-in — every component line is auditable.
**Supersedes:** — **Superseded by:** —
**Related code:** `rules/03-ui-kit.md`

### D-029 · Frontend build stack (2026-06-16) — Locked
**Area:** Architecture
**Decision:** Vite + React + TypeScript strict for the PWA frontend. React Router for client-side routing. TanStack Query for all server state (loading/error/cache). Lucide React for icons. class-variance-authority (CVA) for component variant system.
**Why:** Vite is the standard fast build tool for React PWAs; TanStack Query gives consistent loading/error/refetch behavior app-wide (required by rules/04); CVA enables the variant × size × tone system from rules/03 without prop sprawl.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/` (once scaffolded)

### D-030 · Test stack (2026-06-16) — Locked
**Area:** Architecture
**Decision:** Vitest + React Testing Library (unit/component); Vitest + DynamoDB Local + LocalStack (integration, real services not mocks); Playwright (E2E browser); k6 (performance/load).
**Why:** Vitest is Vite-native and fast; real DynamoDB Local/LocalStack for integration avoids mock-vs-prod divergence (a known risk per rules/05); Playwright for critical journeys; k6 for transcription throughput and search surfaces.
**Supersedes:** — **Superseded by:** —
**Related code:** `rules/05-testing.md`

### D-031 · DynamoDB multi-table design (2026-06-16) — Locked
**Area:** Architecture
**Decision:** Multi-table DynamoDB at launch — one table per service/entity domain. Migration of individual service data to Aurora Serverless v2 or RDS is explicitly kept open for when relational access patterns demand it.
**Why:** Multi-table is simpler to reason about before product shape is settled; single-table requires access pattern certainty upfront that's hard to achieve at MVP. Consistent with D-007 (DynamoDB-only at launch) while keeping the migration path open.
**Supersedes:** — **Superseded by:** —
**Related code:** —

### D-032 · Summarization/extraction model (2026-06-16) — Locked
**Area:** Architecture / Product
**Decision:** Claude API (Anthropic) as the initial LLM for transcript → structured extraction (requirements, decisions, open questions, summary). Implemented behind a provider interface so the model/vendor can be swapped without rewriting the worker.
**Why:** Claude has strong structured extraction from long-form text; provider abstraction future-proofs against model changes, cost optimization, or multi-provider routing. Closes the open item flagged in previous sessions.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-worker-summarization/` (once scaffolded)

### D-033 · REST as API style (2026-06-16) — Locked
**Area:** Architecture
**Decision:** REST over HTTP (JSON) for all frontend ↔ backend communication. Shared contract enforced via `@heediq/shared` — Zod schemas + derived TypeScript types, published as a private package and consumed by all repos.
**Why:** Natural fit for polyrepo (shared types package is necessary regardless); API Gateway HTTP API integrates natively; no TypeScript-only coupling that tRPC would impose; keeps the API surface externally consumable if needed later. tRPC rejected for polyrepo — its main benefit (automatic type sharing) requires monorepo.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/`, `heediq-shared/`

### D-034 · API service runtime — Hono on Lambda (2026-06-16) — Locked
**Area:** Architecture / Infra
**Decision:** All REST API endpoints served by a single Lambda function running the Hono web framework. One deployment unit covers all domains (auth, orgs, recordings, billing) until a service shows clear reason to split (not expected before ~10k MAU).
**Why:** Hono is lightweight (~14kb), TypeScript-native, designed for Lambda + edge runtimes; single Lambda = one deployment, one log group, trivial local dev; same serverless cost model as individual Lambdas with far lower operational burden at <1000 MAU. Always-on containers (Fargate) rejected — $15–30/mo floor at zero traffic.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/`

### D-035 · Polyrepo structure — 7 repos (2026-06-16) — Locked
**Area:** Architecture / Process
**Decision:** Seven repos under the `admin-heediq` GitHub org:
- `heediq-workspace` — rules, memory, plans (exists)
- `heediq-shared` — `@heediq/shared`: Zod schemas + TypeScript types, private GitHub Package
- `heediq-web` — Vite + React PWA
- `heediq-api` — Hono on Lambda (all REST endpoints)
- `heediq-worker-transcription` — Python Fargate (faster-whisper, per D-004/D-005)
- `heediq-worker-summarization` — Node Lambda (Claude API extraction, per D-032)
- `heediq-infra` — AWS CDK (all stacks, all envs per D-036)
**Why:** Microservice-level granularity — workers split because they have different runtimes (Python vs Node) and scaling/cost profiles; shared types in own package consumed across repos; infra separated from application code. Not feature-level (too many repos) and not monorepo (polyrepo locked).
**Supersedes:** — **Superseded by:** D-046
**Related code:** github.com/admin-heediq/

### D-039 · Dev tooling — pnpm + Node 22 LTS (2026-06-16) — Locked
**Area:** Architecture
**Decision:** pnpm as the package manager across all Node/TypeScript repos (web, api, worker-summarization, shared, infra). Node.js 22 LTS as the runtime version for all Node repos and Lambda functions.
**Why:** pnpm is faster and deduplicates packages on disk across 7 repos; strict dependency resolution avoids phantom dep bugs. Node 22 LTS is the current active LTS (supported until April 2027); Lambda supports it natively.
**Supersedes:** — **Superseded by:** —
**Related code:** all Node repos

### D-040 · `@heediq/shared` delivery via GitHub Packages (2026-06-16) — Locked
**Area:** Architecture
**Decision:** `heediq-shared` publishes `@heediq/shared` as a private npm package to GitHub Packages from day one. All other repos install it as a versioned dep. GitHub PAT (or Actions OIDC) authenticates package reads in CI.
**Why:** Polyrepo requires a published package for cross-repo consumption. `file:` path references create brittle dev-vs-CI divergence. GitHub Packages is the natural fit alongside the existing GitHub org.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/`

### D-041 · JWT auth enforcement — Hono middleware (2026-06-16) — Locked
**Area:** Architecture
**Decision:** Cognito JWT validation happens inside the Lambda via Hono middleware (JWKS-based, e.g. `hono/jwt` or `jose`), not at API Gateway. API Gateway is a plain HTTP API with no authorizer.
**Why:** Custom auth logic (role checks, org isolation enforcement, usage-ratchet) lives in the Lambda anyway; centralizing in Hono middleware means one place for all auth/authz rather than splitting between Gateway config and code. Full control over error response shape (per D-033 consistent error envelope).
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/`

### D-042 · API versioning — `/api/v1/` URL prefix (2026-06-16) — Locked
**Area:** Architecture
**Decision:** All REST endpoints are prefixed `/api/v1/` from day one.
**Why:** Zero cost to add now; avoids a painful rename when a second client (native app, partner) can't be force-updated alongside a breaking API change.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/`

### D-043 · CI/CD pipeline structure (2026-06-16) — Locked
**Area:** Infra / Process
**Decision:** Consistent GitHub Actions pattern across all repos:
- **PR** → typecheck + unit tests only (no AWS calls).
- **Merge to `develop`** → assume `GitHubActionsDeployRole` in dev account → deploy to dev.
- **Merge to `main`** → assume role in staging → deploy to staging; manual approval job → assume role in prod → deploy to prod.
- Container images (Fargate workers) push to ECR in the shared-services account first, then ECS deploy in the target workload account.
- `heediq-infra` deploys shared resources (DynamoDB tables, SQS, S3, Cognito) first; app repo workflows deploy only their Lambda/ECS service on top of existing infra. Infra changes are applied before app deploys via workflow dependency or ordering convention.
**Why:** Keeps credentials out of GitHub Secrets (OIDC only); consistent pattern is copy-pasteable across repos; infra-before-app ordering prevents deploy-time resource-not-found errors.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`, all app repos `.github/workflows/`

### D-044 · Primary AWS region — eu-west-1 Ireland (2026-06-17) — Locked
**Area:** Infra
**Decision:** `eu-west-1` (Ireland) is the primary AWS region for all Heediq infrastructure.
**Why:** Most complete service catalog and lowest cost in Europe; strong Fargate Spot capacity; standard choice for EU SaaS startups targeting UK/EU markets. Frankfurt rejected — no DACH enterprise data-residency requirement at this stage. US expansion would add `us-east-1` as a second region later.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`

### D-045 · AWS account IDs + local CLI profiles (2026-06-17) — Locked
**Area:** Infra
**Decision:** Four AWS workload accounts with these IDs and local CLI profile names:
- shared-services: `313828097088` — profile `heediq-shared`
- dev: `276594885933` — profile `heediq-dev`
- staging: `475790160542` — profile `heediq-staging`
- prod: `438825592314` — profile `heediq-prod`

Management account has no local profile (used only for org/billing via SSO console).
**Why:** Canonical reference for scripts, CDK, and disaster recovery. Account boundary = environment boundary per D-036/D-037.
**Supersedes:** — **Superseded by:** —
**Related code:** `claude-workspace/scripts/setup-aws-oidc.sh`, `heediq-infra/`

---

### D-046 · GitHub org rename + workspace repo rename (2026-06-17) — Locked
**Area:** Process / Infra
**Decision:** GitHub org renamed from `admin-heediq` to `heediq`. Workspace repo renamed from `heediq-workspace` to `claude-workspace`. All 7 repos now live under `github.com/heediq/`. Remote: `git@github-heediq:heediq/claude-workspace.git`.
**Why:** cleaner org name; workspace repo name reflects its actual content (Claude workspace config) rather than the product name.
**Supersedes:** D-012, D-035 (org/repo references only; polyrepo structure unchanged)
**Superseded by:** —
**Related code:** `claude-workspace/`

### D-047 · Release versioning strategy (2026-06-17) — Locked
**Area:** Infra / Process
**Decision:** Services (`heediq-api`, `heediq-web`, workers) use git SHA as the version identifier — Docker images tagged `sha-<7chars>`, Lambda deploys tracked by the same SHA. No semver for services at MVP. `@heediq/shared` uses semver from day one (starts at `0.1.0`; graduates to `1.0.0` when the contract stabilises). Docker images built once on `develop` CI, pushed to ECR with the SHA tag, and promoted to staging/prod by updating the ECS task definition — never rebuilt per environment.
**Why:** Services are deployed not consumed, so semver adds overhead with no benefit at MVP. `@heediq/shared` is a published package with multiple consumers, so semver is required for safe dependency pinning. Build-once/promote prevents environment drift.
**Supersedes:** — **Superseded by:** —
**Related code:** all repos `.github/workflows/`, `heediq-shared/`

### D-048 · Renovate for @heediq/shared dependency updates (2026-06-17) — Locked
**Area:** Process
**Decision:** Renovate is configured on all consuming repos (`heediq-api`, `heediq-web`, `heediq-worker-summarization`). When `@heediq/shared` publishes a new version to GitHub Packages, Renovate automatically opens a PR in each consuming repo to bump the dependency. Teams merge when ready.
**Why:** Avoids manual drift where consuming repos fall behind on shared type updates without anyone noticing. Renovate is better than Dependabot for private GitHub Packages in a monorepo-adjacent setup.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/`, consuming repos `renovate.json`

### D-049 · Hotfix flow (2026-06-17) — Locked
**Area:** Process
**Decision:** Hotfixes branch from `main` (`hotfix/xxx`), get a PR directly to `main`, auto-deploy to staging, manual gate to prod. Immediately after merging to prod, open a follow-up PR to merge `main` back into `develop`. Never leave `main` and `develop` diverged after a hotfix.
**Why:** Cutting from `main` ensures the fix targets exactly what's in prod, not unreleased develop work. Mandatory back-merge prevents the fix being silently lost on the next develop → main promotion.
**Supersedes:** — **Superseded by:** —
**Related code:** `rules/02-git-and-commits.md`

### D-050 · Infra-first deployment convention (2026-06-17) — Locked
**Area:** Process / Infra
**Decision:** When a change adds new AWS resources (table, queue, bucket, Cognito config), `heediq-infra` is merged and deployed first; app repos follow after infra deploy succeeds. App repos reference resource names/ARNs via SSM params (per D-038), never hardcoded. This is a process convention enforced by team discipline, not by CI automation at MVP.
**Why:** Prevents deploy-time resource-not-found errors. SSM param indirection means app code never needs to know the exact ARN at build time.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`, `rules/02-git-and-commits.md`

---

### D-051 · DNS — Route 53 hosted zone in shared-services account (2026-06-17) — Locked
**Area:** Infra
**Decision:** The Route 53 public hosted zone for `heediq.com` lives in the shared-services account (`313828097088`). Management account retains minimal footprint (SSO + billing only).
**Why:** Shared-services is already the cross-environment hub (ECR, future shared infra); DNS belongs there rather than polluting the management account with workload-level resources.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`

### D-052 · Subdomain structure per environment (2026-06-17) — Locked
**Area:** Infra
**Decision:** Environment prefix on all non-prod subdomains; prod sits on the root domain. All subdomains are single-level to stay within the wildcard cert coverage:
- Prod: `heediq.com` (web), `api.heediq.com` (API)
- Staging: `staging.heediq.com` (web), `api-staging.heediq.com` (API)
- Dev: `dev.heediq.com` (web), `api-dev.heediq.com` (API)
**Why:** Single-level subdomains are all covered by `*.heediq.com`; two-level subdomains (e.g. `api.staging.heediq.com`) would require additional wildcard certs per environment.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`

### D-053 · ACM certificate strategy (2026-06-17) — Locked
**Area:** Infra
**Decision:** Two wildcard ACM certificates, both covering `heediq.com` + `*.heediq.com`:
- `us-east-1` — used by CloudFront (required by AWS; all CloudFront certs must be in us-east-1)
- `eu-west-1` — used by API Gateway regional endpoint (cert must be co-located with the endpoint)
DNS validation via Route 53 (D-051). No per-subdomain certs unless a specific requirement arises.
**Why:** Single wildcard per region covers all current and future subdomains (D-052) without managing individual certs. Wildcard in both regions needed because CloudFront and API Gateway require certs in different regions.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`

### D-054 · Transactional email via Amazon SES (2026-06-17) — Locked
**Area:** Architecture / Infra
**Decision:** Amazon SES in `eu-west-1` for all transactional email (auth flows, notifications). Domain verified on `heediq.com`; sending address `noreply@heediq.com`. DKIM, SPF, and DMARC configured at domain verification. SES sandbox exit requested before launch.
**Why:** Native AWS service — same account/region as the rest of the stack, CDK-manageable, cheapest at scale ($0.10/1000 emails). Third-party providers (Resend, Postmark) rejected to avoid an extra vendor dependency given existing AWS commitment.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`

---

### D-055 · Compute resource sizing at launch (2026-06-17) — Locked
**Area:** Infra / Cost
**Decision:** All environments (dev/staging/prod) start at identical minimum viable resource settings. Scale up when real traffic demands it — no environment differentiation at launch.
- **Fargate — free-tier transcription task** (whisper small, CPU): 1 vCPU, 2 GB RAM
- **Fargate — paid-tier transcription task** (whisper large-v3 + pyannote, CPU): 4 vCPU, 8 GB RAM. Note: Fargate has no GPU support; large-v3 runs on CPU via Fargate Spot (acceptable for async batch jobs).
- **Lambda — API (Hono, D-034)**: 512 MB, 30s timeout
- **Lambda — summarization worker (D-032)**: 512 MB, 5 min timeout
- **DynamoDB**: `PAY_PER_REQUEST` (on-demand) in all environments — no baseline cost, auto-scales, right for zero-to-low traffic
- **CloudFront price class**: `PriceClass_100` (US + EU edge locations) — fits EU SaaS target market; ~40% cheaper than all-regions
**Why:** No production traffic to justify larger sizing at launch. All settings are reversible CDK config values — scale up when metrics show need.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`, `heediq-worker-transcription/`

---

## Open / proposed (not yet locked)
- **Exact pricing/packaging** — principle locked at D-011/D-019; revisit numbers against the post-D-004 cost basis.
- **SAML/OIDC for enterprise IdPs** — explicitly deferred (D-020); revisit once an enterprise deal needs it.

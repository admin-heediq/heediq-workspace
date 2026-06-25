# Engineering Standards

Additional cross-cutting rules beyond workflow/git/testing. These are the standards I'd add for a
serverless, privacy-sensitive transcription product. Treat as defaults to confirm/refine.

## 1. Type safety & shared contracts
- **One source of truth for shared types** between the React frontend and the Lambda backend — a
  `shared/` package (or schema-generated types). API/DB shapes are defined once and imported on both
  sides so the contract can't silently drift.
- **Validate at every boundary** with a runtime schema (e.g. Zod) — incoming API payloads, queue
  messages, and external responses (Whisper, Recall.ai). Parse, don't trust. The parsed type is the
  type used downstream.
- TypeScript `strict` on. No `any` at module boundaries; if unavoidable internally, isolate and
  comment it.

## 2. Security & privacy (highest priority — this is a transcription product)
- **Transcripts and audio are sensitive PII.** Treat meeting content as confidential by default.
  Encrypt at rest (S3/DynamoDB) and in transit; scope access tightly.
- **Authorize at every API boundary**, not just the UI. Enforce **cross-org / tenant isolation** on
  every read and write — a user can only ever touch their org's data. This is a mandatory test path
  (see `05-testing.md`).
- **Never log PII** — no transcript text, audio URLs with tokens, emails, or secrets in logs. Log IDs
  and metadata only.
- **Secrets live in SSM Parameter Store / Secrets Manager**, never in code, env files committed to
  git, or the frontend bundle. No API keys reach the client.
- **Least privilege** on IAM roles, Lambda permissions, and S3 buckets. Default-deny.
- **Data lifecycle**: define retention/deletion for recordings & transcripts; honor user deletion
  requests fully (audio, transcript, derived summaries, search indexes).

## 3. Error handling & observability
- **Structured errors** with a consistent shape across the API (code, message, optional details);
  the frontend maps these to user-facing messages (`04-loading-and-feedback.md`).
- **React error boundaries** around feature areas so one screen's failure doesn't blank the app; pair
  with a designed ErrorState.
- **Tracing/logging**: structured logs + correlation IDs through the pipeline (API → SQS → ECS (EC2 GPU) →
  DynamoDB); CloudWatch + X-Ray (or equivalent). A failure in a long job must be traceable end to
  end.
- **Frontend error reporting** (e.g. Sentry) for unhandled exceptions, scrubbed of PII.
- Fail loudly in dev, gracefully in prod. No silent catch-and-ignore.

## 4. Cost awareness (Heediq runs on tight per-meeting margins)
- Flag any change that affects **per-meeting transcription cost** (model tier, diarization,
  EC2 Spot vs On-Demand, instance type, silence trimming) in the plan and PR. Cost is a first-class
  review dimension here.
- Respect locked cost decisions: free tier = whisper `small`; paid = `large-v3` + pyannote (both on
  EC2 GPU Spot, g4dn.xlarge, D-059); silence-trim ok (10–30%), no 2× speed-up (accuracy loss).
  Don't quietly change a tier's model assignments or compute economics.
- Watch DynamoDB access patterns (avoid scans/hot partitions), Lambda duration/memory, and S3 egress.

## 5. Accessibility (gate, not nice-to-have)
- Keyboard-operable everything; visible `focus-visible`; correct semantics/ARIA; AA contrast on
  charcoal/amber; `prefers-reduced-motion` honored. Built into kit primitives (`03-ui-kit.md`) and
  verified in component tests.

## 6. Performance budgets
- **Frontend**: watch bundle size (code-split routes, lazy-load heavy views like the transcript/audio
  player); no needless re-renders; virtualize long lists (recordings library, long transcripts).
- **Backend**: mind Lambda cold starts on user-facing paths; keep payloads small; paginate list APIs;
  stream/chunk large transcripts rather than loading whole.
- Long jobs run async via SQS/ECS (EC2 GPU Spot) — never block a request thread on transcription.

## 7. State management (frontend)
- **Server state** via a query/cache library (TanStack Query) — single source of loading/error/
  refetch behavior. **Client/UI state** kept local or in a light store; don't conflate the two.
- No duplicated server data in client state; cache invalidation is explicit.

## 8. API & data conventions
- Consistent response envelope and error shape; consistent pagination (cursor-based for DynamoDB);
  version the API surface so contract changes don't break clients.
- DynamoDB: document key design and access patterns in the module README before adding a table/index;
  single-table or multi-table is a recorded decision, not ad-hoc.

## 9. Naming & conventions
- Files/components: components `PascalCase`, hooks `useX`, utilities `camelCase`, env-agnostic config.
- Branches/commits per `02-git-and-commits.md`. DynamoDB keys and event names follow a documented,
  consistent scheme (record once in the relevant README).
- Feature flags / env config resolved per environment — never hardcoded.

## 10. Dependencies
- Add dependencies deliberately; prefer the platform/existing deps over a new library for small wins.
  Pin versions; note any heavy dep's cost (bundle/runtime) in the PR.

---

## Definition of Done (every change)
- [ ] Workflow steps followed (or low-risk exception justified)
- [ ] Types shared/validated at boundaries; `strict` clean
- [ ] AuthZ + cross-org isolation enforced and tested (for any data path)
- [ ] No PII/secrets in logs, client bundle, or git
- [ ] Errors structured; loading/feedback rules met; a11y satisfied
- [ ] Cost impact considered & noted if relevant
- [ ] Tests added (incl. regression for fixes); pre-PR gate green
- [ ] Nearest code README updated; memory + dependency map actualized

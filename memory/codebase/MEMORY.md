# MEMORY.md — Index

The lean index Claude reads first. Each entry points to a code README or a decision — it does not
duplicate their content. See `rules/08-memory.md` for the contract.

## How to use this file
- At task start, scan for the area you're touching, then open the pointed-to README(s) and decisions.
- After a task, add/correct pointers here for any new or changed module.

## Decisions
- Canonical locked decisions live in **`../business/DECISIONS.md`** (business memory). Reference
  decision IDs (e.g. D-007) from entries below; don't copy decision text here.

## Modules / Features (pointers)

- **heediq-infra** — CDK TypeScript project; all stacks for all accounts.
  README: `../../heediq-infra/README.md` · Decisions: D-036, D-037, D-038, D-044, D-045, D-051–D-064
  - **TranscriptionStack** — EC2 GPU Spot (g4dn.xlarge, D-059); ASG min=0; two Ec2TaskDefs (free/paid, D-060); models baked in image (D-062). Deployed to dev.
  - **FoundationStack** — 5 tables (recordings, orgs, users, jobs w/ DDB Streams NEW_IMAGE, ws-connections w/ TTL + by-recording GSI); ACM wildcard cert eu-west-1 (D-063); 14 SSM params. Deployed to dev.
  - **WebSocketStack** — WebSocket API + heediq-ws-connect + heediq-ws-status-pusher (DDB Streams trigger) + custom domain ws-{env}.heediq.com + Route53AliasRecord (D-064) + 2 SSM params (D-061). Deployed to dev.
  - **ApiStack** — Lambda heediq-api (Node.js 22, 512 MB, 30s) + HTTP API (CfnApi, ANY /{proxy+}, $default stage, CORS) + custom domain api-{env}.heediq.com + Route53AliasRecord + IAM grants (5 tables, S3, SQS transcription+summarization, SecretsManager, SES role) + 2 SSM params. Merged to develop (PR #23). Updated: sqs:SendMessage on summarization queue + SUMMARIZATION_QUEUE_URL env var (D-065).
  - **SummarizationStack** — SQS queue heediq-summarization + DLQ + Lambda heediq-summarization (Node.js 22, 512 MB, 300s) + SQS event source (batchSize=1) + IAM (SecretsManager, DynamoDB jobs+recordings, S3 read) + 3 SSM params. Source-agnostic: audio (transcription worker) + direct path (API Lambda, text/PDF/email/Excel). D-065. PR #24 merged to develop.
  - **WorkloadCfCertStack** — ACM wildcard cert (`*.heediq.com`) in us-east-1 per workload account; cert ARN passed to WebStack via `crossRegionReferences: true`. D-053. PR #25 merged to develop.
  - **WebStack** — CloudFront + S3 OAC + custom domain + security headers (HSTS/X-Frame/CSP) + SPA 403/404→/index.html + Route53AliasRecord (Z2FDTNDATAQYW2) + 2 SSM params. D-053, D-055. Key gotcha: OAC bucket policy must live in FoundationStack (source-account condition) to avoid circular CDK dependency. PR #25 merged to develop.
  - **SharedServicesStack** — ECR, Route 53, SES+DKIM, cross-account IAM roles (heediq-ses-email-sending, heediq-route53-dns-manager D-064). Deployed.

- **heediq-shared** — `@heediq/shared`: Zod schemas + TypeScript types for all cross-repo contracts.
  README: `../../heediq-shared/README.md` · Decisions: D-033, D-040, D-047, D-048
  - Schemas: enums, domain (Org/User/Recording/Job/Summary), API requests, SQS messages (D-023/D-059/D-065), WS push (D-061)
  - `@heediq/shared@0.1.0` published to GitHub Packages. 49 tests.
  - Gotcha: new consuming repos need manual read-access grant in GitHub Packages settings (see README).

- **heediq-api** — Hono Lambda: all REST endpoints under `/api/v1/`, JWT auth middleware, D-060 access control.
  README: `../../heediq-api/README.md` · Decisions: D-033, D-034, D-041, D-042, D-060
  - PR #1 open (feature/api-scaffold → develop). 17 tests (+1 regression for tier SQS attribute). deploy.yml: esbuild bundle → Lambda update on develop push.
  - Critical bug fixed: `SendMessageCommand` now sets `MessageAttributes: { tier }` on transcription enqueue — without this attribute, both EventBridge Pipe filters fail and no job is ever processed.

- **heediq-worker-transcription** — Python ECS worker: one RunTask = one job via SQS_MESSAGE_BODY container override (D-066). Two per-tier images (free/paid) with model weights baked in (D-062).
  README: `../../heediq-worker-transcription/README.md` · Decisions: D-047, D-059, D-062, D-065, D-066
  - Branch `feature/transcription-worker`. 11 pytest tests + mypy strict. deploy.yml: two SHA-tagged images → shared-services ECR → ssm put-parameter + register-task-definition + pipes update-pipe per env.
  - Transcript written to `heediq-recordings[recordingId].transcript` in DynamoDB (task role has no S3 write grant). Downstream summarization worker reads it by recordingId.

<!--
- **<feature/area>** — <one-line summary>.
  README: `path/to/module/README.md` · Decisions: ../business/DECISIONS.md (D-NNN)
-->

## Cross-module gotchas
_(Facts that span multiple modules and don't belong in any single README.)_

## In-progress (not yet doc-worthy)
_(Short notes on things being worked out; promote to a README or decisions doc when settled.)_

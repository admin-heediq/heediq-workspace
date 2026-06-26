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
  - **WorkloadCfCertStack** — ACM wildcard cert (`*.heediq.com`) in us-east-1 per workload account; cert ARN passed to WebStack via `crossRegionReferences: true`. D-053. Branch: feature/web-stack.
  - **WebStack** — CloudFront + S3 OAC + custom domain + security headers (HSTS/X-Frame/CSP) + SPA 403/404→/index.html + Route53AliasRecord (Z2FDTNDATAQYW2) + 2 SSM params. D-053, D-055. Key gotcha: OAC bucket policy must live in FoundationStack (source-account condition) to avoid circular CDK dependency. Branch: feature/web-stack.
  - **SharedServicesStack** — ECR, Route 53, SES+DKIM, cross-account IAM roles (heediq-ses-email-sending, heediq-route53-dns-manager D-064). Deployed.

<!--
- **<feature/area>** — <one-line summary>.
  README: `path/to/module/README.md` · Decisions: ../business/DECISIONS.md (D-NNN)
-->

## Cross-module gotchas
_(Facts that span multiple modules and don't belong in any single README.)_

## In-progress (not yet doc-worthy)
_(Short notes on things being worked out; promote to a README or decisions doc when settled.)_

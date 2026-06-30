# Feature Dependency Map

Drives "what to retest" (Step 2) and PR blast-radius notes. One entry per feature.

## Format
```
### <feature name>
- **Upstream** (this depends on): …
- **Downstream** (breaks if this changes): …
- **Shared surfaces**: files/data models touched by multiple features
```

## Entries

### Infrastructure (heediq-infra)
- **Upstream**: AWS accounts (D-045), locked decisions on naming/sizing/DNS/SES (D-037, D-038, D-051–D-058)
- **Downstream**: all app repos — they deploy code on top of infra resources; all SSM params from FoundationStack must exist before app deploys succeed; `GitHubActionsECRRole` in shared-services account is used by all app repos to push Docker images
- **Shared surfaces**:
  - `lib/config.ts` — account IDs, regions, domains, compute sizing; any change ripples to all stacks
  - `scripts/setup-aws-profiles.sh` — configures AWS SSO profiles for all 4 accounts; owner-only, run once per new machine
  - `scripts/setup.sh` — one-time AWS setup (CDK bootstrap + OIDC providers + IAM roles); upstream for all repos' CI. Must be re-run if org is renamed or trust policy drifts.
  - `scripts/setup-budgets.sh` — creates AWS Budgets via management account

### Transcription pipeline (TranscriptionStack)
- **Upstream**: FoundationStack (SQS `heediq-transcription`, S3 `heediq-audio-uploads-*`, DynamoDB `heediq-jobs` + `heediq-recordings`); SharedServicesStack (ECR repo `heediq-worker-transcription`); per-env SSM params `/heediq/transcription/{free,paid}-image-tag` (written by CI, read by CloudFormation at deploy time)
- **Downstream**: `heediq-worker-transcription` (two per-tier images, D-062; deployed by that repo's CI via register-task-definition + pipes update-pipe); SummarizationStack (indirectly triggered after worker enqueues to heediq-summarization); WebSocket status push via Status Pusher Lambda + DDB Streams on `heediq-jobs` (D-061)
- **Shared surfaces**: `heediq-jobs` table (written by EC2 GPU task, read by Status Pusher Lambda + API); `heediq-recordings` table (written by EC2 GPU task with transcript text); ECR repo (shared pull path per D-045)

### WebSocket real-time status (WebSocketStack)
- **Upstream**: FoundationStack (heediq-jobs DDB Streams stream ARN; heediq-ws-connections table; wildcardCert — ACM wildcard cert eu-west-1, D-063); Cognito (JWKS for JWT validation in Connection Lambda)
- **Downstream**: heediq-web (connects via wss://ws-{env}.heediq.com; receives status push events); heediq-api (Connection Lambda code deployed by heediq-api CI per D-050)
- **Shared surfaces**: heediq-ws-connections table (written by Connect Lambda, read by Status Pusher Lambda); heediq-jobs DDB Streams (read-only by Status Pusher Lambda); SSM /heediq/api/ws-endpoint-url (read by heediq-web and heediq-api)

### Summarization pipeline (SummarizationStack)
- **Upstream**: FoundationStack (heediq-jobs + heediq-recordings DynamoDB tables; heediq-audio-uploads S3 bucket); SummarizationStack (heediq-summarization SQS queue — created here, consumed by Lambda event source)
- **Downstream**: `heediq-worker-summarization` (Node Lambda — placeholder in stack; real implementation deployed by that repo's CI, D-043); `heediq-api` (reads structured output from heediq-recordings); `heediq-web` (displays extraction results)
- **Shared surfaces**:
  - `heediq-summarization` SQS queue — written by TranscriptionStack EC2 task role (audio path) + ApiStack Lambda (direct non-audio path, D-065, D-026); consumed by summarization Lambda
  - `heediq-jobs` table — written by summarization Lambda (status: `summarizing → done/failed`); also written by transcription worker + read by Status Pusher Lambda
  - `heediq-recordings` table — written by summarization Lambda (structured extraction fields); also written by transcription worker + read by ApiStack Lambda
  - `heediq-audio-uploads-*` S3 bucket — read by summarization Lambda (transcript + direct-path content files); also written by API (presigned URL upload)

### Web frontend delivery (WorkloadCfCertStack + WebStack)
- **Upstream**: FoundationStack (heediq-web-assets-{accountId} S3 bucket — OAC bucket policy grant added there; wildcardCert not used here); WorkloadCfCertStack (us-east-1 ACM cert via crossRegionReferences prop, D-053); SharedServicesStack (heediq-route53-dns-manager role for Route53AliasRecord D-064); `lib/config.ts → DOMAINS` (web domain per env)
- **Downstream**: heediq-web (React SPA — served from CloudFront; CI does S3 sync + `aws cloudfront create-invalidation` using `/heediq/web/cloudfront-distribution-id` SSM param); heediq-api (reads `/heediq/web/url` SSM param for CORS origin)
- **Shared surfaces**:
  - `heediq-web-assets-{accountId}` S3 bucket — written by heediq-web CI; served by CloudFront via OAC (source-account policy in FoundationStack)
  - `/heediq/web/url` SSM param — consumed by heediq-api (CORS) and heediq-web (runtime config)
  - `/heediq/web/cloudfront-distribution-id` SSM param — consumed by heediq-web CI for cache invalidation
  - **Key CDK constraint**: OAC bucket policy must live in FoundationStack (source-account condition), not WebStack — avoids circular cross-stack reference. `s3.Bucket.fromBucketName()` in WebStack prevents CDK from adding a second bucket policy.

### @heediq/shared (heediq-shared)
- **Upstream**: nothing — this is the lowest-level package, no runtime dependencies beyond zod
- **Downstream**: `heediq-api` (Zod parse at every API boundary), `heediq-web` (request/response types, WS message types), `heediq-worker-summarization` (SQS message schema + summary domain types)
- **Shared surfaces**: all Zod schemas in `src/` — a breaking change here requires a version bump and coordinated update in all consuming repos (D-047/D-048)

### heediq-api (API Lambda)
- **Upstream**: `heediq-infra` ApiStack (Lambda must exist before code can be deployed, D-050); `@heediq/shared` (types + validation); Cognito User Pool (JWKS endpoint); DynamoDB tables (recordings, orgs, users, jobs, ws-connections); S3 audio bucket; SQS transcription + summarization queues
- **Downstream**: `heediq-web` (REST API consumer); `heediq-worker-transcription` (reads SQS transcription queue messages enqueued here); `heediq-worker-summarization` (reads SQS summarization queue for direct-path uploads, D-065)
- **Shared surfaces**: `heediq-recordings` table (written by API on create; read by API on get/list; also written by summarization worker on completion); `heediq-jobs` table (written by API on enqueue; read by Status Pusher Lambda); SQS queue URLs (SSM params consumed by API env vars)

### heediq-worker-transcription
- **Upstream**: `heediq-infra` TranscriptionStack (EventBridge Pipes + ECS cluster + EC2 GPU Spot ASG + task defs + IAM grants, D-059); `heediq-infra` SharedServicesStack (ECR repo `heediq-worker-transcription`); `heediq-api` (must set `tier` SQS message attribute on enqueue — without it both Pipe filters fail silently); S3 audio bucket (read-only); DynamoDB `heediq-jobs` + `heediq-recordings`; SQS `heediq-transcription` (re-enqueue on SIGTERM, D-066) + `heediq-summarization` (enqueues on completion, D-065)
- **Downstream**: `heediq-worker-summarization` (reads `heediq-recordings[recordingId].transcript` from DynamoDB — NOT from S3; enqueued with `sourceType: 'text', contentRef: recordingId`); `heediq-web` (status push via DDB Streams → Status Pusher Lambda → WebSocket, D-061)
- **Shared surfaces**: `heediq-jobs` table (status writes: `starting → transcribing → diarizing → summarizing → done/failed/retrying`); `heediq-recordings` table (writes `transcript` text field — consumed by summarization worker); DDB Streams on `heediq-jobs` (D-061)

### heediq-worker-summarization
- **Upstream**: `heediq-infra` SummarizationStack (Lambda + SQS event source must exist, D-065); `@heediq/shared` (SummarizationJobMessage schema); DynamoDB `heediq-jobs` + `heediq-recordings` (reads `transcript` from recordings table by `recordingId` when `sourceType='text'`); S3 audio bucket (reads direct-upload content when `sourceType != 'text'`); Secrets Manager (Claude API key)
- **Downstream**: `heediq-api` (reads structured extraction from `heediq-recordings`); `heediq-web` (displays summary output)
- **Shared surfaces**: `heediq-recordings` table (writes structured extraction: requirements, decisions, openQuestions, actionItems); `heediq-jobs` table (writes `status=done/failed` on completion); SQS `heediq-summarization` queue (shared entry point for audio + direct-upload paths, D-065)

### heediq-web (PWA frontend)
- **Upstream**: `heediq-infra` WebStack (CloudFront + S3 bucket must exist before deploy); `heediq-api` (all REST endpoints); WebSocket API (`ws-{env}.heediq.com`, D-061); `@heediq/shared` (request/response types, WS message types); Cognito (auth, federated IdPs)
- **Downstream**: nothing — leaf consumer
- **Shared surfaces**: `/heediq/web/url` SSM param (consumed by `heediq-api` for CORS origin config); `/heediq/web/cloudfront-distribution-id` SSM param (consumed by web CI for cache invalidation); S3 `heediq-web-assets` bucket (written by web CI, served by CloudFront via OAC)

<!--
Template:
### <feature>
- Upstream: ...
- Downstream: ...
- Shared surfaces: ...
-->

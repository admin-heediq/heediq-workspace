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
- **Upstream**: FoundationStack (SQS `heediq-transcription`, S3 `heediq-audio-uploads-*`, DynamoDB `heediq-jobs` + `heediq-recordings`); SharedServicesStack (ECR repo `heediq-worker-transcription` with AllowWorkloadAccountPull policy)
- **Downstream**: `heediq-worker-transcription` (Python EC2 GPU Spot — image deployed by that repo's CI, D-059); SummarizationStack (triggered after job status set to done); WebSocket status push via Status Pusher Lambda + DDB Streams on `heediq-jobs` (D-061)
- **Shared surfaces**: `heediq-jobs` table (written by EC2 GPU task, read by Status Pusher Lambda + API); `heediq-recordings` table (updated by EC2 GPU task); ECR repo (shared pull path with future workers)

### WebSocket real-time status (WebSocketStack)
- **Upstream**: FoundationStack (heediq-jobs DDB Streams stream ARN; heediq-ws-connections table); SharedServicesStack (ACM cert ARN in SSM /heediq/shared/cert-arn-eu-west-1); Cognito (JWKS for JWT validation in Connection Lambda)
- **Downstream**: heediq-web (connects via wss://ws-{env}.heediq.com; receives status push events); heediq-api (Connection Lambda code deployed by heediq-api CI per D-050)
- **Shared surfaces**: heediq-ws-connections table (written by Connect Lambda, read by Status Pusher Lambda); heediq-jobs DDB Streams (read-only by Status Pusher Lambda); SSM /heediq/api/ws-endpoint-url (read by heediq-web and heediq-api)

<!--
### Recording (capture)
- Upstream: auth/onboarding, UI kit (Listen button)
- Downstream: transcription pipeline, recordings library
- Shared surfaces: recordings DynamoDB table, S3 audio bucket
-->

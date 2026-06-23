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
- **Downstream**: `heediq-worker-transcription` (Python Fargate — image deployed by that repo's CI); SummarizationStack (triggered after job status set to done); client polling for job status via `heediq-jobs` table
- **Shared surfaces**: `heediq-jobs` table (written by Fargate task, read by API); `heediq-recordings` table (updated by Fargate task); ECR repo (shared pull path with future workers)

<!--
### Recording (capture)
- Upstream: auth/onboarding, UI kit (Listen button)
- Downstream: transcription pipeline, recordings library
- Shared surfaces: recordings DynamoDB table, S3 audio bucket
-->

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

### claude-workspace/scripts (one-time setup tooling)
- **Upstream**: AWS accounts (D-045), GitHub org `heediq` (D-046)
- **Downstream**: every repo's CI pipeline — `setup-aws-oidc.sh` must be run before any repo can assume an OIDC role and deploy; `setup-budgets.sh` (also here) must be run before dev cost alerts work
- **Shared surfaces**:
  - `scripts/setup-aws-oidc.sh` — creates `GitHubActionsDeployRole` (all 4 accounts, trusts `heediq/heediq-infra:*`) and `GitHubActionsECRRole` (shared-services only, trusts `heediq/*:*`). Originally only created ECR role in shared-services; deploy role for shared-services was added later (needed for heediq-infra CI to deploy SharedServicesStack). Idempotent. Must be re-run if org is renamed or trust policy drifts.
  - `scripts/setup-budgets.sh` — creates AWS Budgets in the management account for the dev account

### Infrastructure (heediq-infra)
- **Upstream**: `claude-workspace/scripts/setup-aws-oidc.sh` (OIDC roles must exist first), AWS accounts (D-045), locked decisions on naming/sizing/DNS (D-037, D-038, D-051–D-055)
- **Downstream**: all app repos — they deploy code on top of infra resources; all SSM params from FoundationStack must exist before app deploys succeed; `GitHubActionsECRRole` in shared-services account is used by all app repos to push Docker images
- **Shared surfaces**: `lib/config.ts` (account IDs, regions, domains, compute sizing) — any change here ripples to all stacks

<!--
### Recording (capture)
- Upstream: auth/onboarding, UI kit (Listen button)
- Downstream: transcription pipeline, recordings library
- Shared surfaces: recordings DynamoDB table, S3 audio bucket

### Transcription pipeline
- Upstream: recording capture, SQS queue, Fargate Spot workers
- Downstream: summary/extraction, recordings library, transcript view
- Shared surfaces: recordings table (status field), transcript storage
-->

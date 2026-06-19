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
- **Upstream**: AWS accounts (D-045), locked decisions on naming/sizing/DNS (D-037, D-038, D-051–D-055)
- **Downstream**: all app repos — they deploy code on top of infra resources; all SSM params from FoundationStack must exist before app deploys succeed; `GitHubActionsECRRole` in shared-services account is used by all app repos to push Docker images
- **Shared surfaces**:
  - `lib/config.ts` — account IDs, regions, domains, compute sizing; any change ripples to all stacks
  - `scripts/setup.sh` — one-time AWS setup (CDK bootstrap + OIDC providers + IAM roles); upstream for all repos' CI. Must be re-run if org is renamed or trust policy drifts.
  - `scripts/setup-budgets.sh` — creates AWS Budgets via management account

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

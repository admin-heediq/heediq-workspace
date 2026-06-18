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
- **Downstream**: all app repos — they deploy code on top of infra resources; all SSM params from FoundationStack must exist before app deploys succeed
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

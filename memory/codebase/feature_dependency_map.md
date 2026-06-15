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
_(Add as features are built. The MVP critical path is: record → transcribe → summarize → view.)_

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

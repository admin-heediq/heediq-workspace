# WIP — heediq-infra CDK scaffold

**Branch:** `chore/cdk-scaffold` in `heediq-infra`
**Status:** PR #1 merged (scaffold + budgets). PR #2 open (SharedServicesStack). Next: FoundationStack.

## What was done

- CDK project scaffolded; `pnpm typecheck` clean; `cdk synth` passes for all environments.
- PR #1 merged: scaffold + budget script (D-056).
- PR #2 open: https://github.com/heediq/heediq-infra/pull/2
  - `SharedServicesStack` (eu-west-1): ECR repo, Route 53 zone, ACM cert eu-west-1.
  - `SharedServicesCfCertStack` (us-east-1): ACM cert for CloudFront.
  - README: OIDC trust policy gotcha documented.
- OIDC trust policies fixed on all 4 accounts via `setup-aws-oidc.sh`:
  - `GitHubActionsDeployRole` sub: `repo:heediq/heediq-infra:*` (wildcard ref — was branch-locked to old org)
  - `GitHubActionsECRRole` sub: `repo:heediq/*:*`

**Post-deploy checklist for SharedServicesStack (before FoundationStack):**
1. ✅ CDK bootstrap all accounts (done per user)
2. ✅ `GitHubActionsDeployRole` in each account (done; trust policies corrected this session)
3. Deploy shared-services via `workflow_dispatch` in CI
4. Capture `HostedZoneId`, `CertArnEuWest1`, `CertArnUsEast1` from CloudFormation outputs
5. Update NS records at domain registrar (NameServers output) → ACM validation completes
6. Fill `config.ts` → `SHARED_SERVICES` fields and commit

## What remains (implementation PRs, in order)

Per D-050 (infra-first), these must land before any app repos deploy:

1. ~~**SharedServicesStack**~~ — done ✓ (PR #2)

2. **FoundationStack** — DynamoDB tables (heediq-recordings, heediq-orgs, heediq-users, heediq-jobs),
   S3 buckets (heediq-audio-uploads, heediq-web-assets), SQS queue (heediq-transcription),
   Cognito User Pool (email/password + Google + Microsoft), SES, SSM param exports.

3. **TranscriptionStack** — ECS cluster, free + paid Fargate task defs, EventBridge Pipe,
   CloudWatch log group.

4. **SummarizationStack** — Lambda, EventBridge trigger, IAM grants.

5. **ApiStack** — Lambda, API Gateway HTTP API, custom domain, IAM grants.

6. **WebStack** — CloudFront distribution, custom domain, Route 53 alias.

## Notes
- Shared-services stack is deployed via `workflow_dispatch` not the normal push pipeline.
- App repos (heediq-api, heediq-web, heediq-worker-transcription) will each get their own
  narrow IAM deploy role added to `setup-aws-oidc.sh` when those repos are scaffolded.
- Cross-account Route 53 record creation (workload → shared-services hosted zone) needs IAM
  cross-account grants on the hosted zone — easiest to set in SharedServicesStack.

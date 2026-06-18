# WIP — heediq-infra CDK scaffold

**Branch:** `chore/cdk-scaffold` in `heediq-infra`
**Status:** Scaffold committed and verified. Next: implement actual stack resources.

## What was done

CDK project scaffolded with all stack skeletons, config, and GitHub Actions workflow.
- `pnpm typecheck` clean; `cdk synth` passes for all environments.
- Branch `chore/cdk-scaffold` exists in heediq-infra. PR not yet opened.

## What remains (implementation PRs, in order)

Per D-050 (infra-first), these must land before any app repos deploy:

1. **SharedServicesStack** — ECR repos, Route 53 hosted zone, ACM certs (us-east-1 + eu-west-1),
   SSM param outputs. Deploy to shared-services account first.

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
- CDK bootstrap needed in all 5 accounts before first deploy (see README).
- Cross-account Route 53 record creation (workload → shared-services hosted zone) needs IAM
  cross-account grants on the hosted zone — easiest to set in SharedServicesStack.

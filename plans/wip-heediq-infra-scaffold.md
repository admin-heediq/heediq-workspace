# WIP — heediq-infra CDK scaffold

**Branch:** all merged to `develop` in `heediq-infra`
**Status:** SharedServicesStack fully deployed. Config filled. Next: FoundationStack.

## What is done

- PRs #1–8 merged to develop and deployed.
- `SharedServicesStack` (eu-west-1): ECR repo, Route 53 hosted zone, ACM cert, Zoho email DNS records (MX/SPF/DMARC/DKIM). **Deployed and CREATE_COMPLETE.**
- `SharedServicesCfCertStack` (us-east-1): ACM wildcard cert for CloudFront. **Deployed and CREATE_COMPLETE.**
- NS records updated at domain registrar → certs validated.
- `lib/config.ts` `SHARED_SERVICES.hostedZoneId` filled (`Z0875312RP7WHSNW7AUM`). Cert ARNs live in SSM, not config (D-038).
- `scripts/setup.sh` — one-time CDK bootstrap + OIDC providers + IAM roles for all 4 accounts. Lives in `heediq-infra/scripts/`.
- CI: `deploy-shared-services.yml` (path-filtered) + `deploy.yml` (workload, excludes shared-services path).
- **`FoundationStack`** — `feature/foundation-stack` branch, **awaiting PR + deployment**. Implements: DynamoDB (4 tables, multi-table per D-031), S3 (audio-uploads + web-assets, account-ID suffix names), SQS (heediq-transcription, 1h visibility, DLQ), Cognito (email/password + Google + Microsoft OIDC IdPs, Cognito-hosted domain, public App Client with localhost URLs for dev), SES (domain identity, DKIM outputs), 11 SSM params. Vitest + 21 CDK unit tests. Pre-PR gate green.
  - **Pre-deploy prerequisite**: create placeholder secrets in dev account (see infra README → FoundationStack Cognito).
  - **Post-deploy follow-up**: capture SES DKIM CNAME outputs → SharedServicesStack update PR (same pattern as Zoho DKIM).

## What remains (in order, per D-050)

1. **FoundationStack PR** — open PR from `feature/foundation-stack`, merge + deploy to dev. Then follow-up SharedServicesStack PR for SES DKIM CNAMEs.

2. **TranscriptionStack** — ECS cluster, free + paid Fargate task defs (D-055), EventBridge Pipe (SQS → RunTask), CloudWatch log group. (After FoundationStack deployed — depends on SQS + S3 + DynamoDB refs from foundation.)

3. **SummarizationStack** — Lambda, EventBridge trigger, IAM grants to Claude API secret.

4. **ApiStack** — Lambda (Hono, D-034), API Gateway HTTP API, custom domain (`api.heediq.com` / `api-dev.heediq.com`), ACM cert from SSM.

5. **WebStack** — CloudFront distribution (D-055 PriceClass_100), custom domain, cert from SSM us-east-1, Route 53 alias.

## Notes

- App repos each need a narrow `GitHubActionsDeployRole` added to `scripts/setup.sh` when those repos are scaffolded.
- Cross-account Route 53 record creation (workload stacks writing DNS aliases into the shared-services hosted zone) needs cross-account IAM grants on the hosted zone — add in FoundationStack or SharedServicesStack update.

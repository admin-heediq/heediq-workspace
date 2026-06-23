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
- **`FoundationStack`** — PR #9 merged to develop. Deployed to dev. DynamoDB (4 tables), S3 (audio-uploads + web-assets), SQS (heediq-transcription), Cognito (Google + Microsoft OIDC IdPs, hosted domain), 12 SSM params. 28 CDK unit tests.
- **SES → SharedServicesStack (D-058)** — PR #10 merged (2026-06-19). SES identity + DKIM CNAMEs + cross-account IAM role in SharedServicesStack. FoundationStack loses SES, gains ses-sending-role-arn SSM param. Test gate added to deploy-shared-services.yml.
- **TranscriptionStack** — PR pending (`feature/transcription-stack`). ECS cluster `heediq-transcription`, free (1 vCPU/2 GB) + paid (4 vCPU/8 GB) Fargate task defs, two EventBridge CfnPipes (free/paid tier filter on SQS messageAttribute), VPC (public subnets, no NAT), IAM execution + task + pipe roles, CloudWatch log group, 23 CDK unit tests. cdk.context.json seeded with eu-west-1 AZs for all workload accounts.

## What remains (in order, per D-050)

1. **TranscriptionStack PR** — open PR from `feature/transcription-stack` → develop. CI deploys updated TranscriptionStack to dev.

2. **SummarizationStack** — Lambda, EventBridge trigger, IAM grants to Claude API secret.

3. **SummarizationStack** — Lambda, EventBridge trigger, IAM grants to Claude API secret.

4. **ApiStack** — Lambda (Hono, D-034), API Gateway HTTP API, custom domain (`api.heediq.com` / `api-dev.heediq.com`), ACM cert from SSM.

5. **WebStack** — CloudFront distribution (D-055 PriceClass_100), custom domain, cert from SSM us-east-1, Route 53 alias.

## Notes

- App repos each need a narrow `GitHubActionsDeployRole` added to `scripts/setup.sh` when those repos are scaffolded.
- Cross-account Route 53 record creation (workload stacks writing DNS aliases into the shared-services hosted zone) needs cross-account IAM grants on the hosted zone — add in FoundationStack or SharedServicesStack update.

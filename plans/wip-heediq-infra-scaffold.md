# WIP — heediq-infra CDK scaffold

**Status:** ApiStack merged (PR #23 ✅). Deployed to dev on next CI run. Next: SummarizationStack.

---

## What is done

- PRs #1–8 merged to develop and deployed.
- `SharedServicesStack` (eu-west-1): ECR repo, Route 53 hosted zone, ACM cert, Zoho email DNS records (MX/SPF/DMARC/DKIM). **Deployed.**
- `SharedServicesCfCertStack` (us-east-1): ACM wildcard cert for CloudFront. **Deployed.**
- NS records updated at domain registrar → certs validated.
- `lib/config.ts` `SHARED_SERVICES.hostedZoneId` filled (`Z0875312RP7WHSNW7AUM`). Cert ARNs live in SSM (D-038).
- `scripts/setup.sh` — CDK bootstrap + OIDC providers + IAM roles for all 4 accounts.
- CI: `deploy-shared-services.yml` (path-filtered) + `deploy.yml` (workload).
- **`FoundationStack`** — PR #9. DynamoDB (4 tables), S3 (audio-uploads + web-assets), SQS (heediq-transcription), Cognito (Google + Microsoft OIDC IdPs), 12 SSM params. 28 CDK unit tests. **Deployed.**
- **SES → SharedServicesStack (D-058)** — PR #10. SES identity + DKIM CNAMEs + cross-account IAM role. **Deployed.**
- **TranscriptionStack (Fargate, D-023/D-055)** — PR #11. ECS cluster, Fargate Spot free (1 vCPU/2 GB) + paid (4 vCPU/8 GB) task defs, two EventBridge CfnPipes, VPC (public subnets, no NAT), IAM roles, CloudWatch log group, 23 CDK unit tests. **Deployed to dev.** Superseded by D-059.
- **TranscriptionStack — GPU migration (D-059, D-060, D-062)** — **PR #12 merged to develop**. Ec2TaskDefinition (bridge mode, gpuCount=1), EC2 Launch Template (ECS-optimized GPU AMI via SSM), ASG (min=0, 100% Spot CAPACITY_OPTIMIZED), AsgCapacityProvider (managed scaling 100%, managed termination protection), instance IAM role, pipes updated to EC2 capacity provider + no networkConfiguration. 30 CDK unit tests. PR #13 open: 2 post-merge fixes (ASCII security group description).
- **WebSocketStack (D-061)** — **Merged to develop ✅ Deployed to dev.** FoundationStack updated (5th table heediq-ws-connections with TTL + by-recording GSI; DDB Streams NEW_IMAGE on heediq-jobs). New HeediqWebSocketStack: WebSocket API Gateway (CfnApi, 3 routes, AWS_PROXY integration), Connection Lambda heediq-ws-connect (29s timeout), Status Pusher Lambda heediq-ws-status-pusher (DDB Streams MODIFY filter, execute-api:ManageConnections), custom domain ws-{env}.heediq.com (Route53AliasRecord, D-064), 2 SSM params. 104 CDK unit tests total.
- **Route53AliasRecord construct** — PR #22 merged. `lib/shared/route53-alias-record.ts` + handler. Reused by WebSocketStack and ApiStack.
- **ApiStack (D-034, D-041, D-042, D-052)** — **PR #23 merged to develop ✅**. Lambda heediq-api (Node.js 22, 512 MB, 30s), HTTP API (CfnApi, ANY /{proxy+}, $default stage, CORS per env), custom domain api-{env}.heediq.com (Route53AliasRecord), IAM grants (5 tables, S3, SQS, SecretsManager, SES role assumption), 2 SSM params (endpoint-url, regional-domain-name). 18 CDK unit tests (104 total green).

---

## What remains (ordered, per D-050)

### ~~1. TranscriptionStack — GPU migration (D-059, D-060)~~ ✅ DONE — PR #12 merged

Branch: `feature/transcription-gpu`

**What changes in `heediq-infra`:**

**`lib/config.ts`**
- Replace `COMPUTE.fargate` transcription entries with a `COMPUTE.gpu` section:
  ```ts
  gpu: {
    instanceType: 'g4dn.xlarge',
    // task resource allocations (CPU/memory for Ec2TaskDefinition)
    free: { cpu: 1024, memoryMiB: 2048 },   // whisper small
    paid: { cpu: 4096, memoryMiB: 8192 },   // large-v3 + pyannote
  }
  ```

**`lib/transcription/transcription-stack.ts`**
1. Remove `FargateTaskDefinition` — add `Ec2TaskDefinition` for each tier with GPU resource: `gpuCount: 1`
2. Add EC2 Launch Template: ECS-optimized GPU AMI (resolved from SSM `aws-ecs-optimized-ami/amazon-linux-2/gpu/recommended/image_id`), instance type `g4dn.xlarge`, user-data registers with ECS cluster
3. Add Auto Scaling Group: `heediq-transcription-asg`, min=0, `SPOT_CAPACITY_OPTIMIZED` allocation, Launch Template
4. Add EC2 capacity provider: `heediq-transcription-ec2`, managed scaling (target=100%), managed termination protection enabled
5. Attach capacity provider to ECS cluster
6. Add IAM instance role: `heediq-transcription-instance` — `AmazonEC2ContainerServiceforEC2Role` managed policy (ECS agent registration, ECR pull, CloudWatch Logs)
7. Update EventBridge Pipe `capacityProviderStrategy` from `FARGATE_SPOT` to the EC2 capacity provider
8. Update CDK unit tests for new resource types (Ec2TaskDefinition, ASG, Launch Template, capacity provider)

**`cdk.context.json`**
- No changes required (AZ cache entries already seeded for all workload accounts)

**Notes:**
- The ECS-optimized GPU AMI SSM path is `aws-ecs-optimized-ami/amazon-linux-2/gpu/recommended/image_id` — resolved at synth time via CDK's `MachineImage.fromSsmParameter()`
- VPC (public subnets, no NAT) is unchanged — EC2 instances need `assignPublicIp` for ECR/S3/DynamoDB access
- Two task definitions + two pipes remain (free/paid) — same SQS filter pattern, only capacity provider changes
- Pipe target still `cluster.clusterArn`; `ecsTaskParameters.capacityProviderStrategy` now references the EC2 provider

**Rollback:** revert `transcription-stack.ts` to PR #11 state — Fargate task defs are kept alongside until GPU is validated in dev.

---

### ~~2. FoundationStack update — heediq-ws-connections table + DDB Streams (D-061)~~ ✅ DONE

Branch: `feature/websocket-stack` (or same branch if done together)

**`lib/foundation/foundation-stack.ts`**
1. Add `heediq-ws-connections` DynamoDB table:
   - PK: `connectionId` (String)
   - GSI: `by-recording` (PK=`recordingId`, projection=ALL)
   - TTL attribute: `expiresAt`
   - `PAY_PER_REQUEST`
2. Enable DDB Streams on `heediq-jobs` table: `streamSpecification: StreamViewType.NEW_IMAGE`
3. Add SSM param `/heediq/api/ws-connections-table-name`
4. Export `jobsTable.tableStreamArn` for WebSocketStack to consume

---

### ~~3. WebSocketStack — new stack (D-061)~~ ✅ DONE

New file: `lib/websocket/websocket-stack.ts`

**Resources:**
1. **API Gateway WebSocket API** — routes: `$connect`, `$disconnect`, `$default`
2. **Connection Lambda** (`heediq-ws-connect`):
   - `$connect`: validates JWT (Cognito JWKS), stores `{connectionId, userId, orgId, recordingId, expiresAt}` in `heediq-ws-connections`
   - `$disconnect`: deletes row from `heediq-ws-connections`
3. **Status Pusher Lambda** (`heediq-ws-status-pusher`):
   - Trigger: DDB Streams on `heediq-jobs` (source ARN from FoundationStack export)
   - On each `MODIFY` event: query `heediq-ws-connections` GSI `by-recording` for the `recordingId`; POST status payload to each `connectionId` via `execute-api:ManageConnections`
   - On `GoneException`: delete stale connection row from table
4. **Custom domain** mapping (`ws.heediq.com` / `ws-staging.heediq.com` / `ws-dev.heediq.com`) — ACM cert from SSM `/heediq/shared/cert-arn-eu-west-1`
5. **IAM**: pusher Lambda role gets `execute-api:ManageConnections` + DynamoDB read on `heediq-ws-connections` + DynamoDB read on `heediq-jobs` stream
6. **New SSM param**: `/heediq/api/ws-endpoint-url`

**`bin/infra.ts`** — instantiate `HeediqWebSocketStack`, pass FoundationStack and jobsTableStreamArn

**`lib/config.ts`** — add `ws` subdomain entries to `DOMAINS`:
```ts
ws: {
  prod:    'ws.heediq.com',
  staging: 'ws-staging.heediq.com',
  dev:     'ws-dev.heediq.com',
} satisfies Record<WorkloadEnv, string>,
```

**CDK unit tests** — `test/websocket-stack.test.ts`

---

### 4. SummarizationStack

Lambda, DDB Streams or SQS trigger (TBD — depends on how summarization is triggered post-transcription), IAM grants for Claude API secret, status writes to `heediq-jobs`.

---

### 5. ApiStack

Lambda (Hono, D-034), API Gateway HTTP API, custom domain (`api.heediq.com` / `api-dev.heediq.com`), ACM cert from SSM. **Access control enforcement** for model selection (D-060): job enqueue endpoint rejects `TIER=paid` requests from free users.

---

### 6. WebStack

CloudFront distribution (`PriceClass_100`, D-055), custom domain, cert from SSM us-east-1, Route 53 alias.

---

## Standing notes

- App repos each need a narrow `GitHubActionsDeployRole` added to `scripts/setup.sh` when those repos are scaffolded.
- Cross-account Route 53 record creation (workload stacks writing DNS aliases into the shared-services hosted zone) needs cross-account IAM grants on the hosted zone — add in FoundationStack or SharedServicesStack update.
- `heediq-worker-transcription` (separate repo) needs: SIGTERM handler (catch → write `status=retrying` → exit), status stage writes (`starting`, `transcribing`, `done/failed`) — separate PR in that repo after GPU infra is deployed.
- `heediq-api` (separate repo) needs: D-060 access control enforcement at job enqueue — separate PR after ApiStack is deployed.

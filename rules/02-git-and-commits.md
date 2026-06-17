# Git, Branching & Commits

Heediq is on **GitHub** with **GitHub Actions** CI/CD. Use the `gh` CLI for PRs.

## Branching model
- **`develop` is the integration / working branch.** Never commit straight to `develop`, `main`, or
  `master`.
- **Every change branches off `develop`** — fix, hotfix, refactor, feature, chore, docs.
- **Branch naming**: `<type>/<short-kebab-desc>` (e.g. `feature/recordings-library`,
  `fix/transcript-overflow`). No issue tracker is in use yet (D-014); if Jira is adopted later,
  switch to `<type>/<KEY>-<short-kebab-desc>`. Types: `feature`, `fix`, `hotfix`, `refactor`,
  `chore`, `docs`, `perf`, `test`. The `claude-workspace` docs repo is exempt — commit memory/plans
  straight to its default branch.
- **One branch = one logical change** (default). A developer may land multiple related commits on one
  branch — their call. At the end of each implementation session, always ask: *"Open a PR now or keep
  working on this branch in another session?"* Don't open a PR unless asked.

## Commit messages
- **Meaningful title + body on every commit.** Title in imperative mood (~50 chars), Conventional
  Commits prefix (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`, `perf:`). Body explains
  **why**, not just what.
- **Issue linking**: no issue tracker is in use yet (D-014), so commits don't carry issue keys. If
  Jira is adopted later, link the real driving issue (`Refs HQ-142` / `Closes HQ-142`) in the footer
  for *sensible* changes (features, behavior/contract changes, multi-file refactors, regression
  risk) — not for trivial fixes.
- **No AI co-author trailer** — commit authorship stays with the human committer; no AI attribution
  in history.
- Never use `--no-verify` or skip hooks/signing unless the user explicitly asks. Fix failing hooks at
  the source.

## Environments
Heediq runs five AWS accounts under one AWS Organization: management, shared-services, dev, staging, prod (D-036). ECR lives in the shared-services account — build once, promote by image tag across environments. GitHub Actions uses OIDC role assumption (no stored credentials) to deploy to each workload account (D-043). Resource names carry no environment prefix — the account IS the environment (D-037). Never hardcode environment values; resolve from CDK-injected env vars for config and Secrets Manager for secrets (D-038). Don't promote an image to staging/prod that hasn't passed the test gate on `develop`.

## Opening Pull Requests
Use `gh pr create --base develop --title "..." --body "..."`. If `gh` isn't installed/authenticated,
print the PR URL from the `git push` output and ask the user to open it manually.

### PR hygiene
- Description states **what & why**, links the issue (sensible changes), and lists the **test
  scenarios** run (reuse the Step 2 QA scenarios).
- **List automated tests**: which unit/integration tests were added/updated; confirm the Step 4.6
  gate is green.
- **Include regression scenarios**, not just happy-path — cover paths that could break in features
  the change touches indirectly.
- **Highlight downstream/affected features** from `feature_dependency_map.md` so reviewers and QA
  know the blast radius.
- Keep PRs reviewable (ideally < ~400 lines of meaningful diff); split otherwise.
- Don't merge your own PR without review unless the user says so. The merged commit keeps the issue
  link.

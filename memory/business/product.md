# Heediq — Product

`DECISIONS.md` (D-010, D-017–D-020, D-022, D-024–D-026) points here rather than duplicating this
detail.

## Vision (founding brief)
Heediq is a business development / requirements-capture assistant. Record or transcribe
in-person meetings and discussions (live mic, audio file upload, or pasted notes), then use AI to
extract structured requirements — functional specs, user stories, decisions made, open questions
— optionally enriched with existing repo/documentation context. Output feeds into tools like
Jira/Confluence.

Target audience: product managers, engineering leads, and BD/client-facing roles at software
companies (B2B, dev-tooling adjacent) who run frequent requirement-gathering meetings and need to
turn discussions into actionable specs without manual note-taking.

Long-term direction: Heediq doesn't just capture requirements — it eventually helps build the
systems behind them (Heed → Define → Build; see `branding.md`).

Original extraction categories envisioned: **Requirements, User Stories, Decisions, Open
Questions, Action Items** — each tagged, source-linked back to the transcript (quote/timestamp),
and editable before export.

Original concept screens (early-stage reference, not all literally in MVP scope — see Build
Order below for what's actually in v1):
- **Dashboard** — session list, status (processing/ready/synced), quick "new session" button
- **New Session** — choose input method (record / upload / paste), optional project/context
- **Session Review** — transcript + extracted items, tabbed (Requirements, User Stories,
  Decisions, Open Questions, Action Items)
- **Item Detail** — each extracted item editable, with source quote/timestamp link
- **Integrations** — connect Jira/Confluence/Drive, map fields (e.g. "Requirement" → Jira
  "Story")
- **Settings** — team members, project contexts, AI extraction preferences/templates per meeting
  type

## Account & roles model
Org-first account model for every user. Personal users = a single-seat org (owner/admin), not a
separate account type — keeps the data model unified.

Roles:
- **Admin** — billing, seats, member management; sees all org content
- **Member** — sees only their own content

No per-recording sharing at launch (deferred; future option is a shareable link or explicit
grant).

## Free tier & billing
Free tier is a per-org shared usage pool with a one-way usage-decay ratchet, based on cumulative
lifetime use (never resets):
- 1 use/day initially
- after 3 lifetime uses → 2 uses/week
- after 6 lifetime uses → 1 use/week

One "use" = one transcription summarized and delivered to the user. Exceeding the limit triggers
a soft upgrade prompt — never a hard block. A single paid plan exists alongside free at launch.

Billing: Stripe. Customer = the org (not the individual user); per-seat quantity-based
subscription. No card required on signup or during trial; Stripe Checkout is only triggered when
the org upgrades. Subscription state (seat count, plan status) is kept in sync via Stripe
webhooks.

Pricing note: an earlier cost-based estimate (when transcription ran on AWS Transcribe at
~$2/meeting) suggested $35–40/seat/month with a fair-use meeting cap as the workable model. The
self-hosted faster-whisper pivot (~70–75× cheaper, see `architecture.md`) makes that exact number
stale — the *principle* (flat per-seat without usage caps doesn't work; fair-use cap does) is
locked, but exact packaging/price is still open and should be revisited against the new cost
basis.

## Auth
AWS Cognito User Pool, with Google and Microsoft (Entra/Azure AD) as federated identity providers
from day one. On signup, email domain is checked against existing org domains — a match surfaces
a "request to join" flow that requires admin approval. Automatic domain-based addition to an org
was explicitly ruled out (security).

## Data retention & audio lifecycle
- **Free tier:** audio + transcript stored 30 days, then audio is deleted; transcript text is
  kept indefinitely (it's the actual product value, and cheap to retain).
- **Paid tier:** audio stored 90 days, then moved to S3 Glacier Deep Archive; transcript text
  kept indefinitely.
- **On cancellation:** 30-day grace period, then full org data deletion.

## Platform — PWA
Mobile-first, desktop-friendly. Installable on both mobile and desktop.
- **Offline recording:** audio captured locally, queued, uploaded on reconnect. Past transcripts
  cached for offline viewing.
- **Background recording:** true lock-screen recording is **not** reliably feasible — iOS Safari
  suspends audio capture once backgrounded. Mitigation: Screen Wake Lock API keeps the screen on
  during recording, with UI messaging explaining why.
- **Push notifications:** built at launch (not deferred) — "transcript ready" alerts via the Web
  Push API. Requires iOS 16.4+ for installed PWAs.
- **Browser/OS baseline:** iOS Safari 16.4+, Android Chrome (last 2 versions), desktop
  Chrome/Edge/Safari/Firefox (last 2 versions).
- **Breakpoints:** mobile <640px, tablet 640–1024px, desktop >1024px.
- **manifest.webmanifest:** name "heediq", background_color `#0E0D0C`, theme_color `#1A1816`,
  display: standalone.

## Home / Listen screen UX
One large "Listen" button (Shazam-style) is the primary CTA, centered. Secondary actions: upload
an audio file, upload a text file (skips transcription, goes straight to summary), view
recordings. A subtle usage/limit indicator sits in the top bar. The recordings library is a
separate nav page, not embedded in home. See `branding.md` for the Listen button's three visual
states and empty-state copy.

## Meeting bot (paid tier)
Automated meeting-join support via a third-party agent (e.g. Recall.ai) with calendar OAuth
integration, rather than building a custom bot in-house — third-party agents already solve
cross-platform call-joining reliably.

## MVP build order
Critical path (the full core loop): **auth/onboarding → home screen → recordings library →
recording detail/summary view** (record → transcribe → summarize → view). Org/billing settings
and calendar/meeting-bot settings are follow-on work, after the core loop is validated.
